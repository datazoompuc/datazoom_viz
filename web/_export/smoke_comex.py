#!/usr/bin/env python3
"""Fumaça do app de COMEX: abre cada combinação de vista, medida, orientação
e escopo num navegador de verdade e confere que o gráfico saiu.

POR QUE ISTO EXISTE
-------------------
Um bug real passou por uma bateria manual que cobria as seis vistas nas duas
medidas: em quantidade, a Composição desenhava eixo e legenda e nenhuma área,
porque as somas viravam NaN. Duas lições viraram as asserções daqui.

A primeira é que a matriz tem que incluir ORIENTAÇÃO e ESCOPO, não só vista e
medida. O bug morava na orientação Estado e nos escopos de município e de UF;
a orientação padrão era justamente um dos caminhos que funcionavam, então
testar o padrão dava verde.

A segunda é que "desenhou alguma coisa" não basta. A página tinha eixo,
legenda e rótulos. O que faltava eram as áreas, e o sintoma no eixo era um
domínio degenerado de 0 a 1. Daí a asserção de MAGNITUDE: o topo do eixo
precisa ser grande o bastante para não ser o fallback. É um piso grosseiro de
propósito, não um valor esperado: número exato quebraria a cada atualização de
dados, e teste que quebra à toa é teste que o time aprende a ignorar.

COMO RODAR LOCALMENTE
---------------------
    pip install playwright && python -m playwright install chromium
    python3 web/_export/smoke_comex.py web/

O argumento é a raiz a servir (`web/` local, `_site/` no CI). O script sobe o
servidor sozinho: `file://` não serve, o navegador bloqueia a leitura dos JSON.
"""

import sys
import re
import json
import threading
import functools
import http.server
import socketserver
from pathlib import Path

from playwright.sync_api import sync_playwright

APP = "comex_exp_municipio"

# Multiplicadores dos sufixos que fmtAbbrev* produz, para converter o rótulo do
# eixo de volta em número. "t" de tonelada vale 1000 porque o eixo de
# quantidade sobe de quilo para tonelada.
SUFIXOS = {
    "bi": 1e9, "mi": 1e6, "mil": 1e3,
    "mi t": 1e9, "mil t": 1e6, "t": 1e3, "kg": 1,
}

# Piso de magnitude. Qualquer total real do COMEX passa de longe disto; um
# domínio degenerado (0..1, de NaN) não chega nem perto. O vão enorme entre os
# dois é o que torna a asserção estável a mudanças de dado.
PISO = 1e4


def parse_valor(rotulo):
    """'US$ 8,0 bi' -> 8.0e9. Devolve None se não reconhecer."""
    txt = rotulo.replace("US$", "").strip()
    m = re.match(r"^([\d.,]+)\s*(mi t|mil t|bi|mi|mil|t|kg)?$", txt)
    if not m:
        return None
    numero = m.group(1).replace(".", "").replace(",", ".")
    try:
        return float(numero) * SUFIXOS.get(m.group(2) or "", 1)
    except ValueError:
        return None


# Conta marcas desenhadas. Precisa das duas famílias: Composição, Explorar,
# Tendências e Mapa desenham em SVG, enquanto Ranking e Variação montam linhas
# de HTML. Uma sonda só de SVG dava falha falsa nessas duas.
SONDA = """() => {
  const w = document.querySelector('.chart-wrap');
  if (!w) return { erro: 'sem .chart-wrap' };
  const svg = [...w.querySelectorAll('svg path, svg rect, svg circle')]
    .filter(e => (e.getAttribute('d') || '').length > 40 || e.tagName !== 'path').length;
  const html = w.querySelectorAll('[class*=rank-], [class*=change-], [class*=bar]').length;
  const eixo = [...w.querySelectorAll('svg text')]
    .map(e => ({ t: e.textContent.trim(), y: parseFloat(e.getAttribute('y') || '1e9') }))
    .filter(o => /US\\$|kg|\\bt\\b/.test(o.t))
    .sort((a, b) => a.y - b.y);
  return {
    marcas: svg + html,
    topo: eixo.length ? eixo[0].t : null,
    carregando: /Carregando|Loading/.test(w.textContent),
    // O app reescreve a URL com o estado que de fato adotou (updateUrl()),
    // então comparar com o que foi pedido revela parâmetro ignorado.
    efetiva: location.search,
  };
}"""


# Parâmetros cujo valor o app normaliza de propósito, e que por isso não
# entram na comparação de pedido contra efetivo: `compproduto` é preenchido com
# a primeira categoria quando vem vazio ou inválido, e `year` pode recuar para
# o último ano completo. Pedido vazio já é pulado na própria comparação, então
# `state` não precisa estar aqui — e não deve: é assim que os casos com UF
# verificam que o filtro pegou.
NORMALIZA = {"compproduto", "year"}


def params_ignorados(pedido, efetiva):
    """Parâmetros que foram pedidos e o app não adotou."""
    quis = dict(p.split("=", 1) for p in pedido.split("&") if "=" in p)
    tem = dict(p.split("=", 1) for p in efetiva.lstrip("?").split("&") if "=" in p)
    fora = []
    for k, v in quis.items():
        if k in NORMALIZA or not v:
            continue
        if tem.get(k) != v:
            fora.append(f"{k}: pedi {v!r}, ficou {tem.get(k)!r}")
    return fora


def casos():
    """A matriz. Cada entrada é (nome, query) e roda nas duas medidas.

    Só o que muda de caminho no código entra aqui. Combinações que apenas
    repintam a mesma consulta ficam de fora: o custo é um page load cada."""
    c = []

    for orient in ["municipio", "produto", "pais"]:
        c.append((f"Ranking/{orient}", f"view=ranking&rankorientation={orient}"))

    # Composição é onde o bug estava, então é a parte densa da matriz: as duas
    # orientações, os dois níveis, e os três escopos (região, UF, município).
    #
    # Só sec e sh2: o select de agregação da Composição não tem País, ao
    # contrário dos das outras vistas. Um caso com `compagg=pais` aqui não
    # falharia, ele cairia calado em sec e testaria sec duas vezes. A
    # checagem de parâmetro efetivo, abaixo, existe para pegar exatamente
    # isso, e foi ela que pegou quando escrevi este arquivo.
    for agg in ["sec", "sh2"]:
        c.append((f"Composicao/produto/{agg}",
                  f"view=composition&comporientation=produto&compagg={agg}"))
    c.append(("Composicao/produto/uf",
              "view=composition&comporientation=produto&compagg=sec&state=PA"))
    c.append(("Composicao/produto/municipio",
              "view=composition&comporientation=produto&compagg=sec&compscope=Parauapebas+-+PA"))
    for agg in ["sec", "sh2"]:
        c.append((f"Composicao/estado/{agg}",
                  f"view=composition&comporientation=estado&compagg={agg}"))
    c.append(("Composicao/estado/uf",
              "view=composition&comporientation=estado&compagg=sec&state=PA"))

    for orient in ["municipio", "produto", "pais"]:
        c.append((f"Tendencias/{orient}", f"view=trends&trendsorientation={orient}"))
        c.append((f"Explorar/{orient}", f"view=explore&exploreorientation={orient}"))
        c.append((f"Variacao/{orient}",
                  f"view=change&changeorientation={orient}&yeara=2000&yearb=2020"))

    c.append(("Mapa", "view=map"))
    return c


def serve(raiz):
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(raiz))
    socketserver.TCPServer.allow_reuse_address = True
    srv = socketserver.TCPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    return srv, srv.server_address[1]


def main():
    raiz = Path(sys.argv[1] if len(sys.argv) > 1 else "web").resolve()
    if not (raiz / APP / "index.html").exists():
        print(f"::error::não achei {APP}/index.html em {raiz}")
        return 1

    srv, porta = serve(raiz)
    base = f"http://127.0.0.1:{porta}/{APP}/"
    falhas = []

    with sync_playwright() as p:
        nav = p.chromium.launch()
        pagina = nav.new_page(viewport={"width": 1280, "height": 860})

        erros = []
        pagina.on("pageerror", lambda e: erros.append(str(e)))

        for nome, query in casos():
            topos = {}
            for medida in ["valor", "kg"]:
                url = f"{base}?lang=pt&year=2015&medida={medida}&{query}"
                erros.clear()
                pagina.goto(url, wait_until="networkidle")
                # networkidle cobre os fetch tardios; esta espera é para o
                # render que acontece depois deles.
                pagina.wait_for_timeout(1200)
                r = pagina.evaluate(SONDA)

                rot = f"{nome} [{medida}]"
                # Erro de JS vem primeiro de propósito: quando ele existe, as
                # outras falhas são consequência dele, e reportar o sintoma
                # mandaria quem for consertar para o lugar errado.
                if erros:
                    falhas.append((rot, f"erro de JS: {erros[0][:160]}", url))
                    continue
                if r.get("erro"):
                    falhas.append((rot, r["erro"], url))
                    continue
                if r["carregando"]:
                    falhas.append((rot, "preso em Carregando", url))
                    continue
                if r["marcas"] < 3:
                    falhas.append((rot, f"nada desenhado ({r['marcas']} marcas)", url))
                    continue

                # Um parâmetro que o app ignora transforma o caso num
                # duplicado silencioso de outro: o teste fica verde cobrindo
                # menos do que o nome diz.
                ignorados = params_ignorados(f"medida={medida}&{query}", r["efetiva"])
                if ignorados:
                    falhas.append((rot, "parâmetro ignorado, este caso não testa o que diz: "
                                        + "; ".join(ignorados), url))
                    continue

                if r["topo"]:
                    v = parse_valor(r["topo"])
                    topos[medida] = v
                    if v is not None and v < PISO:
                        falhas.append((
                            rot,
                            f"eixo degenerado: topo {r['topo']!r} = {v:g}, abaixo do piso {PISO:g}. "
                            "Sintoma de soma NaN, o gráfico desenha a moldura e nenhum dado.",
                            url))
                print(f"  {rot:34s} marcas={r['marcas']:<4d} topo={r['topo']}")

            # Dólar e quilo não podem dar o mesmo eixo. Se derem, a troca de
            # medida não chegou nos dados, só no rótulo.
            if len(topos) == 2 and None not in topos.values() and topos["valor"] == topos["kg"]:
                falhas.append((nome, f"valor e kg deram o mesmo topo ({topos['valor']:g}): "
                                     "a troca de medida não chegou nos dados", base + "?" + query))

    srv.shutdown()

    print()
    if falhas:
        print(f"::error::{len(falhas)} falha(s) na fumaça do COMEX")
        for rot, motivo, url in falhas:
            print(f"  {rot}: {motivo}")
            print(f"    {url}")
        return 1
    print(f"OK: {len(casos()) * 2} combinações, nenhuma falha.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
