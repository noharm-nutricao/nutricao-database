CREATE TABLE demo.nutricional_llm_resumo (
    id              BIGSERIAL    PRIMARY KEY,
    context_hash    CHAR(64)     NOT NULL,
    nratendimento   BIGINT       NOT NULL,
    report_type     VARCHAR(40)  NOT NULL,
    max_assessments SMALLINT     NOT NULL,
    status          VARCHAR(16)  NOT NULL DEFAULT 'pending',  -- pending|processing|done|failed
    prompt_version  VARCHAR(60)  NOT NULL,
    model           VARCHAR(60),
    summary         TEXT,
    tokens_used     INTEGER,
    error_code      VARCHAR(40),
    error_message   TEXT,
    attempts        SMALLINT     NOT NULL DEFAULT 0,
    lease_until     TIMESTAMP,
    created_at      TIMESTAMP    NOT NULL DEFAULT now(),
    processed_at    TIMESTAMP,
    expires_at      TIMESTAMP,
    CONSTRAINT uq_llm_resumo_hash UNIQUE (context_hash)
);
CREATE INDEX ix_llm_resumo_claim ON nutricional_llm_resumo (created_at)
    WHERE status IN ('pending', 'processing');
CREATE INDEX ix_llm_resumo_atend ON nutricional_llm_resumo (nratendimento);

CREATE TABLE public.cognito_token_cache (
    id           SMALLINT     PRIMARY KEY DEFAULT 1,
    access_token TEXT         NOT NULL,            -- CIFRADO (Fernet)
    token_type   VARCHAR(20)  NOT NULL DEFAULT 'Bearer',
    expires_at   TIMESTAMPTZ  NOT NULL,
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT cognito_token_singleton CHECK (id = 1)
);