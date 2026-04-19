-- =============================================================
-- NITRA — dados de teste para desenvolvimento local
-- =============================================================

-- -------------------------------------------------------------
-- Segmentos
-- -------------------------------------------------------------
INSERT INTO demo.segmento (idsegmento, nome, status, tp_segmento, cpoe, cpoe_ambulatorio)
VALUES
    (3,   'Segmento UTI', NULL, 3, false, false),
    (10,  'Ala B',        NULL, 1, false, false),
    (11,  'Ala C',        NULL, 1, false, false),
    (903, 'Segmento UTI', NULL, 3, false, false)
ON CONFLICT (idsegmento) DO UPDATE
    SET nome         = EXCLUDED.nome,
        tp_segmento  = EXCLUDED.tp_segmento;

-- -------------------------------------------------------------
-- Setores
-- -------------------------------------------------------------
INSERT INTO demo.setor (fkhospital, fksetor, nome)
VALUES
    (1, 900, 'UTI'),
    (1,  10, 'Ala B'),
    (1,  11, 'Ala C')
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------------
-- Mapeamento setor → segmento
-- -------------------------------------------------------------
DELETE FROM demo.segmentosetor WHERE fkhospital = 1 AND fksetor IN (10, 11, 900);
INSERT INTO demo.segmentosetor (idsegmento, fkhospital, fksetor)
VALUES
    (903,  1, 900),
    ( 10,  1,  10),
    ( 11,  1,  11);

-- -------------------------------------------------------------
-- Pacientes UTI (fksetor=900, sem prescrição)
-- -------------------------------------------------------------
INSERT INTO demo.pessoa (fkpessoa, nratendimento, fkhospital, fksetor, leito, dtnascimento, dtinternacao, peso, altura, idcid)
VALUES
    (100, 990100, 1, 900, 'UTI-01', '1948-03-12', NOW() - INTERVAL '5 days',  80, 175, 'J18'),
    (101, 990101, 1, 900, 'UTI-02', '1960-08-22', NOW() - INTERVAL '3 days',  65, 162, 'K57'),
    (102, 990102, 1, 900, 'UTI-03', '1985-01-10', NOW() - INTERVAL '1 day',   90, 180, 'I50'),
    (103, 990103, 1, 900, 'UTI-04', '1955-11-05', NOW() - INTERVAL '4 days',  72, 168, 'J96')
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------------
-- Paciente UTI com prescrição (idsegmento=903)
-- -------------------------------------------------------------
INSERT INTO demo.pessoa (fkpessoa, fkhospital, nratendimento, dtnascimento, sexo, dtinternacao, peso, cor, fksetor, leito, idcid)
VALUES (990001, 1, 990001900, '1958-04-10', 'M', (NOW() AT TIME ZONE 'America/Sao_Paulo') - INTERVAL '5 days', 82, 'B', 900, 'UTI-01', 'J18.9')
ON CONFLICT DO NOTHING;

INSERT INTO demo.exame (fkexame, fkpessoa, nratendimento, dtexame, tpexame, resultado, unidade)
VALUES (990001, 990001, 990001900, NOW() AT TIME ZONE 'America/Sao_Paulo', 'CR', 1.1, 'mg/dL')
ON CONFLICT DO NOTHING;

INSERT INTO demo.prescricao (fkhospital, fksetor, fkprescricao, fkpessoa, idsegmento, dtprescricao, status, nratendimento, update_at, update_by, agregada, indicadores, leito, tp_revisao)
VALUES (1, 900, 990001900001, 990001, 903, NOW() AT TIME ZONE 'America/Sao_Paulo', '0', 990001900, NOW() AT TIME ZONE 'America/Sao_Paulo', 1, NULL, NULL, 'UTI-01', 0)
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------------
-- Pacientes Ala B (fksetor=10)
-- -------------------------------------------------------------
INSERT INTO demo.pessoa (fkpessoa, nratendimento, fkhospital, fksetor, leito, dtnascimento, dtinternacao, peso, altura, idcid)
VALUES
    (110, 991001, 1, 10, 'B-01', '1952-06-18', NOW() - INTERVAL '7 days',  55, 160, 'K86'),
    (111, 991002, 1, 10, 'B-02', '1938-09-04', NOW() - INTERVAL '10 days', 48, 155, 'C34'),
    (112, 991003, 1, 10, 'B-03', '1970-04-25', NOW() - INTERVAL '2 days',  82, 172, NULL)
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------------
-- Triagens UTI — mNUTRIC
-- -------------------------------------------------------------
INSERT INTO demo.nutricional_triagem (nratendimento, protocolo, mn_idade, mn_apache, mn_sofa, mn_comor, mn_dias, mn_total, mn_apache_manual, mn_sofa_manual, classificacao)
VALUES
    (990100, 'MNUTRIC', 2, 3, 2, 0, 1, 8,    true,  true,  'cr'),
    (990101, 'MNUTRIC', 1, 2, 1, 0, 1, 5,    true,  true,  'al'),
    (990102, 'MNUTRIC', 0, 2, 1, 0, 0, 3,    true,  true,  'md'),
    (990103, 'MNUTRIC', 1, NULL, NULL, 0, 1, NULL, false, false, NULL)
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------------
-- Triagens Ala B — NRS-2002
-- -------------------------------------------------------------
INSERT INTO demo.nutricional_triagem (nratendimento, protocolo, nrs_nut, nrs_doenca, nrs_idade, nrs_total, nrs_completo, classificacao)
VALUES
    (991001, 'NRS2002', 2, 2, 1, 5, true, 'cr'),
    (991002, 'NRS2002', 3, 1, 1, 5, true, 'cr'),
    (991003, 'NRS2002', 1, 1, 0, 2, true, 'bx')
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------------
-- Pacientes UTI adicionais
-- -------------------------------------------------------------
INSERT INTO demo.pessoa (fkpessoa, nratendimento, fkhospital, fksetor, leito, dtnascimento, dtinternacao, peso, altura, idcid)
VALUES
    (200, 990200, 1, 900, 'UTI-05', '1988-02-14', NOW() - INTERVAL '8 days',  95, 183, NULL),
    (201, 990201, 1, 900, 'UTI-06', '1957-11-30', NOW() - INTERVAL '2 days',  70, 169, 'I10'),
    (202, 990202, 1, 900, 'UTI-07', '1946-05-08', NOW() - INTERVAL '6 days',  58, 160, 'C50')
ON CONFLICT DO NOTHING;

INSERT INTO demo.nutricional_triagem (nratendimento, protocolo, mn_idade, mn_apache, mn_sofa, mn_comor, mn_dias, mn_total, mn_apache_manual, mn_sofa_manual, classificacao)
VALUES
    (990200, 'MNUTRIC', 0, 3, 2, 0, 1, 6,    true,  true,  'al'),
    (990201, 'MNUTRIC', 1, 1, 0, 1, 1, 4,    true,  true,  'md'),
    (990202, 'MNUTRIC', 2, NULL, NULL, 1, 1, NULL, false, false, NULL)
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------------
-- Pacientes Ala B adicionais
-- -------------------------------------------------------------
INSERT INTO demo.pessoa (fkpessoa, nratendimento, fkhospital, fksetor, leito, dtnascimento, dtinternacao, peso, altura, idcid)
VALUES
    (210, 991200, 1, 10, 'B-04', '1953-03-22', NOW() - INTERVAL '5 days',  42, 158, 'K92'),
    (211, 991201, 1, 10, 'B-05', '1981-07-10', NOW() - INTERVAL '1 day',   78, 174, NULL),
    (212, 991202, 1, 10, 'B-06', '1965-12-19', NOW() - INTERVAL '3 days',  65, 165, 'E11')
ON CONFLICT DO NOTHING;

INSERT INTO demo.nutricional_triagem (nratendimento, protocolo, nrs_nut, nrs_doenca, nrs_idade, nrs_total, nrs_completo, classificacao)
VALUES
    (991200, 'NRS2002', 3, 2, 1, 6,    true,  'cr'),
    (991201, 'NRS2002', 0, 1, 0, 1,    true,  'bx'),
    (991202, 'NRS2002', NULL, NULL, NULL, NULL, false, NULL)
ON CONFLICT DO NOTHING;
