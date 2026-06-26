-- =============================================================
-- Ala B — seed de todos os estados de triagem NRS-2002
--
-- pendente    : internação < 24h, sem nutricional_triagem
-- atrasada    : internação > 24h, sem nutricional_triagem
--               (estado transitório: vira em_andamento após o job rodar)
-- em_andamento: internação > 24h, triagem com nrs_total calculado
--               mas nrs_nut = NULL (formulário NRS não preenchido)
-- finalizada  : nutricional_nrs preenchido + triagem_at carimbado
-- =============================================================

-- -------------------------------------------------------------
-- Pacientes
-- -------------------------------------------------------------
INSERT INTO demo.pessoa (fkpessoa, nratendimento, fkhospital, fksetor, leito, dtnascimento, dtinternacao, peso, altura, idcid)
VALUES
    -- pendente: < 24h
    (300, 991300, 1, 10, 'B-07', '1972-04-10', NOW() - INTERVAL '10 hours', 68, 168, 'J18'),
    -- atrasada: > 24h, job ainda não rodou para este paciente
    (301, 991301, 1, 10, 'B-08', '1945-09-22', NOW() - INTERVAL '6 days',  52, 155, 'C34'),
    -- em_andamento: job calculou B+C mas nrs_nut=NULL (formulário não preenchido)
    (303, 991303, 1, 10, 'B-10', '1958-03-20', NOW() - INTERVAL '3 days',  71, 172, 'J18'),
    -- finalizada
    (302, 991302, 1, 10, 'B-09', '1960-07-15', NOW() - INTERVAL '4 days',  74, 170, 'K57')
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------------
-- nutricional_triagem para em_andamento
-- Job calculou B (doença=1 via CID C34) + C (idade=1, ≥70) mas
-- A (nrs_nut) está NULL porque nutricional_nrs não existe.
-- Após mudança em _build_campo1: dados_incompletos=True → em_andamento.
-- Pacientes 991001-991003 e 991200-991202 do V5 já caem aqui.
-- -------------------------------------------------------------

-- em_andamento: job calculou nrs_total (B+C) mas nrs_nut=NULL (formulário admissional ausente)
-- _build_campo1 detecta nrs_nut=NULL → dados_incompletos=True → em_andamento
INSERT INTO demo.nutricional_triagem (
    nratendimento, protocolo,
    nrs_nut, nrs_doenca, nrs_idade, nrs_total, nrs_completo, classificacao,
    triagem_at, calculado_at
)
VALUES (
    991303, 'NRS2002',
    NULL, 1, 0, 1, false, 'md',
    NULL, NOW() - INTERVAL '2 days'
)
ON CONFLICT DO NOTHING;

-- finalizada: triagem com triagem_at já carimbado
INSERT INTO demo.nutricional_triagem (
    nratendimento, protocolo,
    nrs_nut, nrs_doenca, nrs_idade, nrs_total, nrs_completo, classificacao,
    triagem_at, calculado_at
)
VALUES (
    991302, 'NRS2002',
    2, 1, 0, 3, true, 'al',
    NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'
)
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------------
-- nutricional_nrs para o paciente finalizado (991302)
-- Garante que o job não reverta nrs_completo=true no próximo ciclo.
-- -------------------------------------------------------------
INSERT INTO demo.nutricional_nrs (
    nratendimento,
    triagem_imc_baixo, triagem_perda_peso, triagem_ingestao_reduzida, triagem_doenca_grave,
    score_comprometimento, score_gravidade, idade_maior_70,
    created_at, updated_at
)
VALUES (
    991302,
    false, true, true, false,
    2, 1, false,
    NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'
)
ON CONFLICT DO NOTHING;
