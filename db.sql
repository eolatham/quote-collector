CREATE TABLE IF NOT EXISTS "user" (
    id uuid NOT NULL,
    username text NOT NULL,
    email text NOT NULL,
    password text NOT NULL,
    first_name text,
    last_name text,
    PRIMARY KEY (id),
    UNIQUE (username),
    UNIQUE (email)
);
CREATE TABLE IF NOT EXISTS quote (
    id uuid NOT NULL,
    quote text NOT NULL,
    creator uuid NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (quote, creator),
    CONSTRAINT fk_creator FOREIGN KEY (creator) REFERENCES "user" (id)
);
CREATE TABLE IF NOT EXISTS tag (
    id uuid NOT NULL,
    tag text NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (tag)
);
CREATE TABLE IF NOT EXISTS quote_to_tag (
    quote uuid NOT NULL,
    tag uuid NOT NULL,
    PRIMARY KEY (quote, tag),
    CONSTRAINT fk_quote FOREIGN KEY (quote) REFERENCES quote (id),
    CONSTRAINT fk_tag FOREIGN KEY (tag) REFERENCES tag (id)
);
CREATE TABLE IF NOT EXISTS collection (
    id uuid NOT NULL,
    title text NOT NULL,
    description text,
    creator uuid NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (title, creator),
    CONSTRAINT fk_creator FOREIGN KEY (creator) REFERENCES "user" (id)
);
CREATE TABLE IF NOT EXISTS collection_to_quote (
    collection uuid NOT NULL,
    quote uuid NOT NULL,
    PRIMARY KEY (collection, quote),
    CONSTRAINT fk_collection FOREIGN KEY (collection) REFERENCES collection (id),
    CONSTRAINT fk_quote FOREIGN KEY (quote) REFERENCES quote (id)
);
CREATE TABLE IF NOT EXISTS follows (
    follower uuid NOT NULL,
    "user" uuid,
    tag uuid,
    PRIMARY KEY (follower, "user", tag),
    CONSTRAINT fk_follower FOREIGN KEY (follower) REFERENCES "user" (id),
    CONSTRAINT fk_user FOREIGN KEY ("user") REFERENCES "user" (id),
    CONSTRAINT fk_tag FOREIGN KEY (tag) REFERENCES tag (id),
    CHECK (("user" IS NOT NULL AND tag IS NULL) OR ("user" IS NULL AND tag IS NOT NULL))
);
CREATE TABLE IF NOT EXISTS likes (
    "user" uuid NOT NULL,
    quote uuid,
    collection uuid,
    PRIMARY KEY ("user", quote, collection),
    CONSTRAINT fk_user FOREIGN KEY ("user") REFERENCES "user" (id),
    CONSTRAINT fk_quote FOREIGN KEY (quote) REFERENCES quote (id),
    CONSTRAINT fk_collection FOREIGN KEY (collection) REFERENCES collection (id),
    CHECK ((quote IS NOT NULL AND collection IS NULL) OR (quote IS NULL AND collection IS NOT NULL))
);
