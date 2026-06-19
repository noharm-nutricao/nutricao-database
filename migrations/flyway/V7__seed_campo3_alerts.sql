-- Seed: dados para testar alertas Campo 3 (clin + lab)
--
-- Clin path: INSERT em evolucao → trigger popula nutricional_aux_alerta.
--   Se a trigger não disparar (linhas já existiam com ON CONFLICT), o bloco
--   abaixo faz o INSERT direto na aux_alerta como safety-net idempotente.
--
-- Lab path: INSERT em exame → trigger popula nutricional_aux_alerta.

-- ---------------------------------------------------------------
-- CLIN: evoluções com sintomas — pacientes UTI da V5
--   990100 (UTI-01) · 990101 (UTI-02) · 990102 (UTI-03) · 990103 (UTI-04)
-- ---------------------------------------------------------------
INSERT INTO demo.evolucao (
    fkevolucao, nratendimento, texto, dtevolucao,
    prescritor, cargo, exame, anotacoes
) VALUES
(9900001, 990100, 'Paciente relata vômitos frequentes nas últimas 12h.', NOW(),
 'Dr. Seed', 'Médico', false, '{"sintomas": ["vomito"]}'),
(9900002, 990101, 'Paciente mantido em jejum prolongado por indicação cirúrgica.', NOW(),
 'Dr. Seed', 'Médico', false, '{"sintomas": ["jejum"]}'),
(9900003, 990102, 'Episódios de diarreia — 4x/dia.', NOW(),
 'Dr. Seed', 'Médico', false, '{"sintomas": ["diarreia"]}'),
(9900004, 990103, 'Vômitos e diarreia concomitantes.', NOW(),
 'Dr. Seed', 'Médico', false, '{"sintomas": ["vomito", "diarreia"]}')
ON CONFLICT DO NOTHING;

-- Corrige nratendimento caso as linhas existissem de uma versão anterior do seed
UPDATE demo.evolucao SET nratendimento = 990100 WHERE fkevolucao = 9900001 AND nratendimento != 990100;
UPDATE demo.evolucao SET nratendimento = 990101 WHERE fkevolucao = 9900002 AND nratendimento != 990101;
UPDATE demo.evolucao SET nratendimento = 990102 WHERE fkevolucao = 9900003 AND nratendimento != 990102;
UPDATE demo.evolucao SET nratendimento = 990103 WHERE fkevolucao = 9900004 AND nratendimento != 990103;

-- Safety-net: garante aux_alerta mesmo que a trigger não tenha disparado
INSERT INTO demo.nutricional_aux_alerta (nratendimento, fkevolucao, reconhecido)
SELECT e.nratendimento, e.fkevolucao, false
  FROM demo.evolucao e
 WHERE e.fkevolucao IN (9900001, 9900002, 9900003, 9900004)
   AND NOT EXISTS (
       SELECT 1 FROM demo.nutricional_aux_alerta a
        WHERE a.fkevolucao = e.fkevolucao
   );

-- ---------------------------------------------------------------
-- LAB: exames com valores fora da referência (segmentoexame V6)
--   Ranges: ALB 3.5-5.2 · HB 12-17 · P 2.5-4.5 · MG 1.7-2.4 · K 3.5-5.1 · PCR 0-0.5
--
--   990100 (UTI-01): ALB=2.1 ↓  K=6.5 ↑  → 2 alterados → severidade al
--   990101 (UTI-02): HB=9.0  ↓             → 1 alterado  → severidade md
--   990102 (UTI-03): P=1.8 ↓  MG=3.0 ↑  PCR=3.5 ↑ → 3 alterados → severidade cr
--   991001 (Ala B):  ALB=3.0 ↓             → 1 alterado  → severidade md
-- ---------------------------------------------------------------
INSERT INTO demo.exame (fkexame, fkpessoa, nratendimento, dtexame, tpexame, resultado, unidade)
VALUES
(9910001, 100, 990100, NOW(), 'ALB',  2.1, 'g/dL'),
(9910002, 100, 990100, NOW(), 'K',    6.5, 'mEq/L'),
(9910003, 101, 990101, NOW(), 'HB',   9.0, 'g/dL'),
(9910004, 102, 990102, NOW(), 'P',    1.8, 'mg/dL'),
(9910005, 102, 990102, NOW(), 'MG',   3.0, 'mg/dL'),
(9910006, 102, 990102, NOW(), 'PCR',  3.5, 'mg/dL'),
(9910007, 110, 991001, NOW(), 'ALB',  3.0, 'g/dL')
ON CONFLICT DO NOTHING;
