-- rastreabilidade: qual evolução/presmed originou cada alerta
ALTER TABLE demo.nutricional_alerta
ADD COLUMN IF NOT EXISTS fk_origem_gatilho_evol BIGINT,
ADD COLUMN IF NOT EXISTS fk_origem_gatilho_pres BIGINT;

CREATE TABLE demo.nutricional_aux_alerta(
    id SERIAL PRIMARY KEY,
    nratendimento BIGINT NOT NULL REFERENCES demo.pessoa(nratendimento),
    fkevolucao BIGINT NULL,
    fkpresmed BIGINT NULL,
    reconhecido BOOLEAN DEFAULT false
);

----------TRIGGER CRIA ALERTA EVOLUCAO----------
DROP FUNCTION IF EXISTS demo.cria_aux_alerta_evolucao();

CREATE OR REPLACE FUNCTION demo.cria_aux_alerta_evolucao()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN

    INSERT INTO demo.nutricional_aux_alerta (
        nratendimento,
        fkevolucao,
        reconhecido
    )
    VALUES (
        NEW.nratendimento,
        NEW.fkevolucao,
        false
    );

    RETURN NEW;

END;
$function$;

ALTER FUNCTION demo.cria_aux_alerta_evolucao() OWNER TO CURRENT_USER;

DROP TRIGGER IF EXISTS trg_cria_aux_alerta_evolucao
ON demo.evolucao;

CREATE TRIGGER trg_cria_aux_alerta_evolucao
AFTER INSERT
ON demo.evolucao
FOR EACH ROW
EXECUTE FUNCTION demo.cria_aux_alerta_evolucao();
-------------FIM DA TRIGGER-------------

----------TRIGGER CRIA ALERTA PRESMED----------
CREATE OR REPLACE FUNCTION demo.cria_aux_alerta_presmed()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    v_nratendimento BIGINT;
BEGIN

    IF lower(trim(NEW.origem)) IN ('dieta', 'dietas') THEN

        SELECT p.nratendimento
        INTO v_nratendimento
        FROM demo.prescricao p
        WHERE p.fkprescricao = NEW.fkprescricao;

        IF v_nratendimento IS NULL THEN
            RAISE EXCEPTION
                'Prescrição % não encontrada',
                NEW.fkprescricao;
        END IF;

    END IF;

    INSERT INTO demo.nutricional_aux_alerta (
        nratendimento,
        fkpresmed,
        reconhecido
    )
    VALUES (
        v_nratendimento,
        NEW.fkpresmed,
        false
    );

    RETURN NEW;
END;
$function$;

ALTER FUNCTION demo.cria_aux_alerta_presmed() OWNER TO CURRENT_USER;

DROP TRIGGER IF EXISTS trg_cria_aux_alerta_presmed
ON demo.presmed;

CREATE TRIGGER trg_cria_aux_alerta_presmed
AFTER INSERT
ON demo.presmed
FOR EACH ROW
EXECUTE FUNCTION demo.cria_aux_alerta_presmed();
-------------FIM DA TRIGGER-------------

-- remver NOT NULL da coluna reconhecido_por para iniciar alerta com
-- essa coluna nula (ficar assim até alguém reconhecer)
ALTER TABLE demo.nutricional_alerta
ALTER COLUMN reconhecido_por DROP NOT NULL;

ALTER TABLE demo.nutricional_alerta
DROP CONSTRAINT nutricional_alerta_severidade_check;

UPDATE demo.nutricional_alerta
SET severidade = CASE lower(trim(severidade))
    WHEN 'amarelo' THEN 'md'
    WHEN 'laranja' THEN 'al'
    WHEN 'vermelho' THEN 'cr'
    ELSE lower(trim(severidade))
END
WHERE severidade IS NOT NULL;

-- alterado constraint de check para severidade
ALTER TABLE demo.nutricional_alerta
ADD CONSTRAINT nutricional_alerta_severidade_check_updated
CHECK (severidade IN ('md', 'al', 'cr'));

INSERT INTO demo.segmentoexame
    (idsegmento, tpexame, abrev, nome, min, max, referencia, posicao, ativo, update_by)
SELECT s.idsegmento, e.tpexame, e.abrev, e.nome, e.min, e.max, e.referencia, e.posicao, true, 1
FROM (VALUES (1), (3), (10), (11), (903)) AS s(idsegmento)
CROSS JOIN (VALUES
    ('ALB', 'Alb', 'Albumina',    3.5::float4, 5.2::float4,  '3.5-5.2 g/dL',  1::smallint),
    ('HB',  'Hb',  'Hemoglobina', 12.0::float4, 17.0::float4, '12-17 g/dL',    2::smallint),
    ('P',   'P',   'Fosforo',     2.5::float4, 4.5::float4,   '2.5-4.5 mg/dL', 3::smallint),
    ('MG',  'Mg',  'Magnesio',    1.7::float4, 2.4::float4,   '1.7-2.4 mg/dL', 4::smallint),
    ('K',   'K',   'Potassio',    3.5::float4, 5.1::float4,   '3.5-5.1 mEq/L', 5::smallint),
    ('PCR', 'PCR', 'PCR',         0.0::float4, 0.5::float4,   '< 0.5 mg/dL',   6::smallint)
) AS e(tpexame, abrev, nome, min, max, referencia, posicao)
ON CONFLICT (idsegmento, tpexame) DO NOTHING;

ALTER TABLE demo.nutricional_aux_alerta ADD COLUMN IF NOT EXISTS fkexame BIGINT NULL;

CREATE OR REPLACE FUNCTION demo.cria_aux_alerta_exame()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    v_nratendimento BIGINT;
    v_tp            VARCHAR(100);
BEGIN
    v_tp := upper(trim(NEW.tpexame));

    IF v_tp NOT IN ('ALB', 'HB', 'P', 'MG', 'K', 'PCR') THEN
        RETURN NEW;
    END IF;

    v_nratendimento := NEW.nratendimento;
    IF v_nratendimento IS NULL AND NEW.fkprescricao IS NOT NULL THEN
        SELECT p.nratendimento INTO v_nratendimento
          FROM demo.prescricao p
         WHERE p.fkprescricao = NEW.fkprescricao;
    END IF;
    IF v_nratendimento IS NULL THEN
        RETURN NEW;
    END IF;

    INSERT INTO demo.nutricional_aux_alerta (nratendimento, fkexame, reconhecido)
    VALUES (v_nratendimento, NEW.fkexame, false);

    RETURN NEW;
END;
$function$;

ALTER FUNCTION demo.cria_aux_alerta_exame() OWNER TO CURRENT_USER;

DROP TRIGGER IF EXISTS trg_cria_alerta_exame ON demo.exame;
DROP FUNCTION IF EXISTS demo.cria_alerta_exame();
DROP TRIGGER IF EXISTS trg_cria_aux_alerta_exame ON demo.exame;

CREATE TRIGGER trg_cria_aux_alerta_exame
AFTER INSERT
ON demo.exame
FOR EACH ROW
EXECUTE FUNCTION demo.cria_aux_alerta_exame();
