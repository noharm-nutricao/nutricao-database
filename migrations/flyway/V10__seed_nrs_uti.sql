-- =============================================================
-- V10 — nutricional_nrs seed para pacientes UTI
--
-- Fornece o Componente A (NRS-2002) dos pacientes UTI definidos
-- em V5 para que o job de recálculo produza scores completos
-- (nrs_completo = true) ao rodar sobre o schema demo.
--
-- Comp B é fixo = 3 para UTI (hardcoded no serviço).
-- Comp C = 1 se idade >= 70.
-- Total esperado: score_comprometimento + 3 + comp_c.
-- =============================================================

INSERT INTO demo.nutricional_nrs (
    nratendimento,
    triagem_imc_baixo,
    triagem_perda_peso,
    triagem_ingestao_reduzida,
    triagem_doenca_grave,
    score_comprometimento,
    score_gravidade,
    idade_maior_70,
    updated_at,
    created_at
) VALUES
    -- 990100 | nasc. 1948 → 70+ | CID J18 → total esperado: 2+3+1 = 6 'cr'
    (990100, true,  true,  false, false, 2, 3, true,  NOW(), NOW()),
    -- 990101 | nasc. 1960 | CID K57 → total esperado: 1+3+0 = 4 'al'
    (990101, false, true,  true,  false, 1, 3, false, NOW(), NOW()),
    -- 990102 | nasc. 1985 | CID I50 → sem risco admissional → 0+3+0 = 3 'al'
    (990102, false, false, false, false, 0, 3, false, NOW(), NOW()),
    -- 990103 | nasc. 1955 (~70) | CID J96 → total esperado: 3+3+1 = 7 'cr'
    (990103, true,  true,  true,  true,  3, 3, true,  NOW(), NOW()),
    -- 990200 | nasc. 1988 | sem CID → total esperado: 1+3+0 = 4 'al'
    (990200, true,  false, true,  false, 1, 3, false, NOW(), NOW()),
    -- 990201 | nasc. 1957 | CID I10 → sem risco admissional → 0+3+0 = 3 'al'e3
    (990201, false, false, false, false, 0, 3, false, NOW(), NOW()),
    -- 990202 | nasc. 1946 → 70+ | CID C50 → total esperado: 2+3+1 = 6 'cr'
    (990202, true,  false, true,  true,  2, 3, true,  NOW(), NOW()),
    -- 990001900 | nasc. 1958 | CID J18.9 → total esperado: 1+3+0 = 4 'al'
    (990001900, false, true, true, false, 1, 3, false, NOW(), NOW())
ON CONFLICT DO NOTHING;
