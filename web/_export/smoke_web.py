#!/usr/bin/env python3
"""Fumaça dos apps estáticos: abre cada combinação de controles num navegador
de verdade e confere que o gráfico ou o mapa saiu.

POR QUE ISTO EXISTE
-------------------
Validar JSON e sintaxe de JS não prova que o app funciona. Um bug real passou
pelas duas: em quantidade, a Composição do COMEX desenhava eixo e legenda e
nenhuma área, porque as somas viravam NaN. Três lições viraram as asserções
daqui, e valem para qualquer app novo que entre na lista.

1. A matriz precisa das DIMENSÕES INTERNAS, não só da vista. O bug morava na
   orientação Estado e nos escopos de município e de UF; a orientação padrão
   era justamente um caminho que funcionava, então testar o padrão dava verde.

2. "Desenhou alguma coisa" não basta. A página tinha eixo, legenda e rótulos;
   faltavam só as áreas. Por isso cada app devolve uma ASSINATURA do que
   pintou (o topo do eixo, as cores do coroplético) e o teste exige que ela
   seja plausível.

3. Controle que não faz nada tem que falhar. Duas combinações diferentes que
   produzem assinatura idêntica são ou um parâmetro ignorado ou um filtro que
   não chegou aos dados. Isto pegou um caso de teste meu que era duplicata
   disfarçada: `compagg=pais` na Composição cai calado em `sec`, porque aquele
   select só tem sec e sh2.

APPS AUSENTES SÃO PULADOS, de propósito: os dois apps vivem em branches
diferentes, e cada uma monta um site com só o seu. Se NENHUM for encontrado o
script falha, senão o passo ficaria verde sem testar nada.

COMO RODAR LOCALMENTE
---------------------
    pip install playwright && python -m playwright install chromium
    python3 web/_export/smoke_web.py web/

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


# ---------------------------------------------------------------- utilitários

# Multiplicadores dos sufixos que o fmtAbbrev dos apps produz, para converter
# um rótulo de eixo de volta em número. "t" de tonelada vale 1000 porque o eixo
# de quantidade sobe de quilo para tonelada.
SUFIXOS = {
    "bi": 1e9, "mi": 1e6, "mil": 1e3,
    "mi t": 1e9, "mil t": 1e6, "t": 1e3, "kg": 1,
}

# Piso de magnitude para um eixo. Qualquer total real destes dados passa de
# longe disto; um domínio degenerado (0..1, vindo de NaN) não chega perto. O
# vão enorme entre os dois é o que torna a asserção estável a mudanças de dado.
# Valor esperado exato quebraria a cada atualização, e teste que quebra à toa é
# teste que o time aprende a ignorar.
PISO_EIXO = 1e4


def parse_valor(rotulo):
    """'US$ 8,0 bi' -> 8.0e9. Devolve None se não reconhecer."""
    txt = rotulo.replace("US$", "").replace("R$", "").strip()
    m = re.match(r"^([\d.,]+)\s*(mi t|mil t|bi|mi|mil|t|kg)?$", txt)
    if not m:
        return None
    try:
        return float(m.group(1).replace(".", "").replace(",", ".")) * SUFIXOS.get(m.group(2) or "", 1)
    except ValueError:
        return None


def params_ignorados(pedido, efetiva, normaliza):
    """Parâmetros que foram pedidos e o app não adotou.

    O app reescreve a URL com o estado que de fato assumiu (updateUrl()), então
    comparar pedido com efetivo revela parâmetro ignorado. Um parâmetro ignorado
    transforma o caso num duplicado silencioso de outro: o teste fica verde
    cobrindo menos do que o nome diz."""
    quis = dict(p.split("=", 1) for p in pedido.split("&") if "=" in p)
    tem = dict(p.split("=", 1) for p in efetiva.lstrip("?").split("&") if "=" in p)
    return [f"{k}: pedi {v!r}, ficou {tem.get(k)!r}"
            for k, v in quis.items()
            if v and k not in normaliza and tem.get(k) != v]


# ------------------------------------------------------------- COMEX (gráfico)

SONDA_COMEX = """() => {
  const w = document.querySelector('.chart-wrap');
  if (!w) return { erro: 'sem .chart-wrap' };
  // Conta as duas famílias: Composição, Explorar, Tendências e Mapa desenham
  // em SVG, enquanto Ranking e Variação montam linhas de HTML. Uma sonda só de
  // SVG dava falha falsa nessas duas.
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
    efetiva: location.search,
  };
}"""


def casos_comex():
    c = []
    for orient in ["municipio", "produto", "pais"]:
        c.append((f"Ranking/{orient}", f"view=ranking&rankorientation={orient}"))

    # Composição é onde o bug estava, então é a parte densa da matriz: as duas
    # orientações, os dois níveis, e os três escopos (região, UF, município).
    #
    # Só sec e sh2: o select de agregação da Composição não tem País, ao
    # contrário dos das outras vistas. Um caso com `compagg=pais` não falharia,
    # cairia calado em sec e testaria sec duas vezes.
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

    # Cada caso roda nas duas medidas, agrupado para a comparação de assinatura:
    # dólar e quilo não podem produzir o mesmo eixo. Se produzirem, a troca de
    # medida chegou no rótulo e não nos dados.
    return [{"nome": f"{nome} [{m}]", "grupo": nome,
             "query": f"lang=pt&year=2015&medida={m}&{q}"}
            for nome, q in c for m in ["valor", "kg"]]


def verifica_comex(r):
    if r["topo"]:
        v = parse_valor(r["topo"])
        if v is not None and v < PISO_EIXO:
            return (f"eixo degenerado: topo {r['topo']!r} = {v:g}, abaixo do piso "
                    f"{PISO_EIXO:g}. Sintoma de soma NaN: o gráfico desenha a moldura "
                    "e nenhum dado.")
    return None


# -------------------------------------------------------------- CEMPRE (mapa)

# Num coroplético o equivalente ao eixo degenerado é o mapa todo da mesma cor:
# desenha, parece certo de longe, e não ligou dado nenhum. A assinatura é o
# conjunto de cores de preenchimento, e a asserção é que haja mais de uma.
SONDA_CEMPRE = """() => {
  // O app cria painéis próprios (leaflet-paneMain para os municípios,
  // leaflet-paneBoundaries para as fronteiras) em vez de usar o
  // leaflet-overlay-pane padrão, que fica VAZIO. Procurar no painel padrão foi
  // o primeiro jeito que escrevi isto, e ele acusava "o Leaflet não montou"
  // nos nove casos enquanto o mapa estava perfeito na tela.
  //
  // Daí varrer todos os SVG do map-pane e ficar com o que tem mais polígonos:
  // é o coroplético, qualquer que seja o nome do painel. Pegar o painel pelo
  // nome amarraria o teste a um detalhe que o app pode mudar sem quebrar nada.
  const svgs = [...document.querySelectorAll('.leaflet-map-pane svg')];
  if (!svgs.length) return { erro: 'o Leaflet não montou nenhum painel de vetores' };
  const alvo = svgs.map(s => ({ s, n: s.querySelectorAll('path').length }))
                   .sort((a, b) => b.n - a.n)[0].s;
  const paths = [...alvo.querySelectorAll('path')];
  const cores = {};
  for (const p of paths) {
    const f = p.getAttribute('fill');
    if (f) cores[f] = (cores[f] || 0) + 1;
  }
  const legenda = document.querySelector('.legend');
  return {
    marcas: paths.length,
    cores: Object.keys(cores).length,
    // Ordenado para a assinatura não depender da ordem de pintura.
    assinatura: JSON.stringify(Object.entries(cores).sort()),
    legenda: legenda ? legenda.textContent.replace(/\\s+/g, ' ').trim().slice(0, 60) : null,
    carregando: /Carregando|Loading/.test(document.body.textContent),
    efetiva: location.search,
  };
}"""

VARS_CEMPRE = [
    "cempre_n_empresas_organizacoes",
    "cempre_n_ocupados",
    "cempre_n_ocupados_assalariados",
    "cempre_salarios_remuneracoes",
]


def casos_cempre():
    c = []
    # Uma variável por vez no mesmo ano: quatro mapas que têm que diferir entre
    # si, senão o select de variável não chegou aos dados.
    for v in VARS_CEMPRE:
        c.append({"nome": f"var/{v.replace('cempre_', '')}", "grupo": "variaveis",
                  "query": f"lang=pt&x={v}&filter=2015"})
    # O mesmo para o ano, com a variável fixa.
    for ano in [2006, 2013, 2020]:
        c.append({"nome": f"ano/{ano}", "grupo": "anos",
                  "query": f"lang=pt&x={VARS_CEMPRE[0]}&filter={ano}"})
    # Inglês, que troca rótulos e formatação de número.
    c.append({"nome": "en", "grupo": None,
              "query": f"lang=en&x={VARS_CEMPRE[0]}&filter=2015"})
    # Comparação de anos não tem parâmetro de URL, só o botão.
    c.append({"nome": "comparar anos", "grupo": None,
              "query": f"lang=pt&x={VARS_CEMPRE[0]}&filter=2015",
              "clique": "#compare-toggle"})
    return c


def verifica_cempre(r):
    if r["cores"] <= 1:
        return (f"mapa de uma cor só ({r['cores']}): desenhou {r['marcas']} polígonos e "
                "nenhum degradê. Sintoma de dado que não ligou na geometria.")
    if not r["legenda"]:
        return "mapa sem legenda: sem ela as cores não querem dizer nada"
    return None


# ----------------------------------------------------------------- o registro

APPS = {
    "comex_exp_municipio": {
        "sonda": SONDA_COMEX,
        "casos": casos_comex,
        "verifica": verifica_comex,
        "assinatura": lambda r: r["topo"],
        # `compproduto` é preenchido com a primeira categoria quando vem vazio
        # ou inválido, e `year` pode recuar para o último ano completo. Pedido
        # vazio já é pulado na própria comparação, então `state` não precisa
        # estar aqui, e não deve: é assim que os casos com UF verificam que o
        # filtro pegou.
        "normaliza": {"compproduto", "year"},
    },
    "map_dz_munic_cempre": {
        "sonda": SONDA_CEMPRE,
        "casos": casos_cempre,
        "verifica": verifica_cempre,
        "assinatura": lambda r: r["assinatura"],
        # O app escreve o ano como `filter`, e o lê do mesmo nome, mas a
        # comparação de anos reescreve para o par corrente.
        "normaliza": {"filter"},
    },
}


# ------------------------------------------------------------------- execução

def serve(raiz):
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(raiz))
    socketserver.TCPServer.allow_reuse_address = True
    srv = socketserver.TCPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    return srv, srv.server_address[1]


def roda_app(pagina, base, app, cfg, falhas):
    assinaturas = {}  # grupo -> {assinatura: nome do caso}
    erros = []
    pagina.on("pageerror", lambda e: erros.append(str(e)))

    for caso in cfg["casos"]():
        nome, query = caso["nome"], caso["query"]
        url = f"{base}?{query}"
        erros.clear()
        pagina.goto(url, wait_until="networkidle")
        if caso.get("clique"):
            pagina.click(caso["clique"])
        # networkidle cobre os fetch tardios; esta espera é para o render que
        # acontece depois deles, e para a animação do Leaflet assentar.
        pagina.wait_for_timeout(1500)
        r = pagina.evaluate(cfg["sonda"])

        # Erro de JS vem primeiro de propósito: quando ele existe, as outras
        # falhas são consequência, e reportar o sintoma mandaria quem for
        # consertar para o lugar errado.
        if erros:
            falhas.append((f"{app}/{nome}", f"erro de JS: {erros[0][:160]}", url))
            continue
        if r.get("erro"):
            falhas.append((f"{app}/{nome}", r["erro"], url))
            continue
        if r["carregando"]:
            falhas.append((f"{app}/{nome}", "preso em Carregando", url))
            continue
        if r["marcas"] < 3:
            falhas.append((f"{app}/{nome}", f"nada desenhado ({r['marcas']} marcas)", url))
            continue

        ignorados = params_ignorados(query, r["efetiva"], cfg["normaliza"])
        if ignorados:
            falhas.append((f"{app}/{nome}",
                           "parâmetro ignorado, este caso não testa o que diz: "
                           + "; ".join(ignorados), url))
            continue

        problema = cfg["verifica"](r)
        if problema:
            falhas.append((f"{app}/{nome}", problema, url))
            continue

        # Dois casos do mesmo grupo com a mesma assinatura significam um
        # controle que não faz nada, ou um caso de teste duplicado.
        grupo, ass = caso.get("grupo"), cfg["assinatura"](r)
        if grupo and ass is not None:
            anterior = assinaturas.setdefault(grupo, {}).get(ass)
            if anterior:
                falhas.append((f"{app}/{nome}",
                               f"assinatura idêntica à de {anterior!r}: o controle não "
                               "chegou aos dados, ou os dois casos testam a mesma coisa",
                               url))
            else:
                assinaturas[grupo][ass] = nome

        resumo = r.get("topo") or f"{r.get('cores')} cores"
        print(f"  {app}/{nome:38s} marcas={r['marcas']:<5d} {resumo}")


def main():
    raiz = Path(sys.argv[1] if len(sys.argv) > 1 else "web").resolve()
    presentes = [a for a in APPS if (raiz / a / "index.html").exists()]
    if not presentes:
        print(f"::error::nenhum app conhecido em {raiz}. Conhecidos: {', '.join(APPS)}")
        return 1
    ausentes = [a for a in APPS if a not in presentes]
    if ausentes:
        print(f"Pulando (não estão neste site): {', '.join(ausentes)}")

    srv, porta = serve(raiz)
    falhas = []
    total = 0

    with sync_playwright() as p:
        nav = p.chromium.launch()
        for app in presentes:
            cfg = APPS[app]
            total += len(cfg["casos"]())
            print(f"\n{app}:")
            pagina = nav.new_page(viewport={"width": 1280, "height": 860})
            roda_app(pagina, f"http://127.0.0.1:{porta}/{app}/", app, cfg, falhas)
            pagina.close()
        nav.close()

    srv.shutdown()

    print()
    if falhas:
        print(f"::error::{len(falhas)} falha(s) na fumaça dos apps")
        for rot, motivo, url in falhas:
            print(f"  {rot}: {motivo}")
            print(f"    {url}")
        return 1
    print(f"OK: {total} combinações em {len(presentes)} app(s), nenhuma falha.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
