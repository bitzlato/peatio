SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: block_numbers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.block_numbers (
    id bigint NOT NULL,
    blockchain_id bigint NOT NULL,
    transactions_processed_count integer DEFAULT 0 NOT NULL,
    number bigint NOT NULL,
    status character varying NOT NULL,
    error_message character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: block_numbers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.block_numbers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: block_numbers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.block_numbers_id_seq OWNED BY public.block_numbers.id;


--
-- Name: blockchain_addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blockchain_addresses (
    id bigint NOT NULL,
    address_type character varying NOT NULL,
    address public.citext NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    private_key_hex_encrypted character varying(1024),
    category character varying(16) DEFAULT 'deposit'::character varying NOT NULL
);


--
-- Name: COLUMN blockchain_addresses.private_key_hex_encrypted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.blockchain_addresses.private_key_hex_encrypted IS 'Is must be NOT NULL but vault-rails does not support it';


--
-- Name: blockchain_addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blockchain_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blockchain_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blockchain_addresses_id_seq OWNED BY public.blockchain_addresses.id;


--
-- Name: blockchain_currencies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blockchain_currencies (
    id bigint NOT NULL,
    blockchain_id bigint NOT NULL,
    currency_id character varying(20) NOT NULL,
    contract_address character varying,
    gas_limit bigint,
    parent_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    base_factor bigint NOT NULL,
    withdraw_fee numeric(32,18) DEFAULT 0.0 NOT NULL,
    min_deposit_amount numeric(32,18) DEFAULT 0.0 NOT NULL
);


--
-- Name: blockchain_currencies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blockchain_currencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blockchain_currencies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blockchain_currencies_id_seq OWNED BY public.blockchain_currencies.id;


--
-- Name: blockchain_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blockchain_transactions (
    id bigint NOT NULL,
    currency_id character varying NOT NULL,
    reference_type character varying,
    reference_id bigint,
    txid public.citext,
    from_address public.citext,
    to_address public.citext,
    amount numeric(36,18) DEFAULT 0.0 NOT NULL,
    block_number integer,
    txout integer,
    status character varying,
    options json,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    fee numeric(36,18),
    fee_currency_id character varying,
    blockchain_id bigint NOT NULL,
    is_followed boolean DEFAULT false NOT NULL,
    "to" integer,
    "from" integer,
    kind integer,
    direction integer,
    instruction_id integer
);


--
-- Name: blockchain_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blockchain_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blockchain_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blockchain_transactions_id_seq OWNED BY public.blockchain_transactions.id;


--
-- Name: blockchains; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blockchains (
    id bigint NOT NULL,
    key character varying NOT NULL,
    name character varying,
    height bigint,
    explorer_address character varying,
    explorer_transaction character varying,
    min_confirmations integer DEFAULT 6 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    explorer_contract_address character varying,
    client_version character varying,
    height_updated_at timestamp without time zone,
    high_transaction_price_at timestamp without time zone,
    disable_collection boolean DEFAULT false NOT NULL,
    address_type character varying,
    chain_id integer,
    allowance_enabled boolean DEFAULT false NOT NULL,
    client character varying,
    status character varying,
    client_options jsonb DEFAULT '{}'::jsonb NOT NULL,
    server_encrypted character varying(1024),
    current_block_number bigint DEFAULT 0 NOT NULL
);


--
-- Name: blockchains_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blockchains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blockchains_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blockchains_id_seq OWNED BY public.blockchains.id;


--
-- Name: currencies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.currencies (
    id character varying(15) NOT NULL,
    "precision" smallint DEFAULT 8 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deposit_enabled boolean DEFAULT true NOT NULL,
    type character varying(30) DEFAULT 'coin'::character varying NOT NULL
);


--
-- Name: deposit_addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deposit_addresses (
    id bigint NOT NULL,
    address character varying(95),
    details_encrypted character varying(1024),
    member_id bigint NOT NULL,
    blockchain_id bigint NOT NULL,
    balances jsonb DEFAULT '"{}"'::jsonb,
    balances_updated_at timestamp without time zone,
    collection_state character varying DEFAULT 'none'::character varying NOT NULL,
    collected_at timestamp without time zone,
    gas_refueled_at timestamp without time zone,
    last_transfer_try_at timestamp without time zone,
    last_transfer_status character varying,
    enqueued_generation_at timestamp without time zone,
    archived_at timestamp without time zone,
    parent_id bigint,
    blockchain_currency_id bigint,
    app_key character varying(64) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: deposit_addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.deposit_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deposit_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.deposit_addresses_id_seq OWNED BY public.deposit_addresses.id;


--
-- Name: deposits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deposits (
    id bigint NOT NULL,
    member_id bigint NOT NULL,
    currency_id character varying(20) NOT NULL,
    amount numeric(36,18) NOT NULL,
    fee numeric(36,18) NOT NULL,
    blockchain_id bigint NOT NULL,
    txid public.citext,
    address character varying(95),
    aasm_state character varying(30) DEFAULT 'submitted'::character varying NOT NULL,
    type character varying(30) NOT NULL,
    txout integer,
    block_number integer,
    from_addresses text,
    error json,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: deposits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.deposits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deposits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.deposits_id_seq OWNED BY public.deposits.id;


--
-- Name: legacy_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.legacy_transactions (
    id bigint NOT NULL,
    account character varying,
    address character varying,
    category character varying,
    amount character varying NOT NULL,
    label character varying,
    vout bigint,
    confirmations bigint,
    blockhash character varying,
    blockindex bigint,
    blocktime bigint,
    txid public.citext NOT NULL,
    walletconflicts jsonb,
    "time" bigint NOT NULL,
    timereceived bigint NOT NULL,
    "bip125-replaceable" character varying,
    fee numeric(36,18),
    abandoned boolean,
    blockchain_id bigint NOT NULL,
    currency_id character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    aml_status_requested_at timestamp without time zone,
    aml_status_processed_at timestamp without time zone,
    aml_status character varying(256)
);


--
-- Name: legacy_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.legacy_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: legacy_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.legacy_transactions_id_seq OWNED BY public.legacy_transactions.id;


--
-- Name: members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.members (
    id bigint NOT NULL,
    uid character varying(32) NOT NULL,
    email character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.members_id_seq OWNED BY public.members.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: wallets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wallets (
    id bigint NOT NULL,
    name character varying(64),
    address character varying NOT NULL,
    blockchain_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: wallets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wallets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wallets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.wallets_id_seq OWNED BY public.wallets.id;


--
-- Name: whitelisted_smart_contracts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.whitelisted_smart_contracts (
    id bigint NOT NULL,
    description character varying,
    address character varying NOT NULL,
    state character varying(30) NOT NULL,
    blockchain_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: whitelisted_smart_contracts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.whitelisted_smart_contracts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: whitelisted_smart_contracts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.whitelisted_smart_contracts_id_seq OWNED BY public.whitelisted_smart_contracts.id;


--
-- Name: withdraws; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.withdraws (
    id bigint NOT NULL,
    txid public.citext,
    aasm_state character varying(30) NOT NULL,
    block_number integer,
    blockchain_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: withdraws_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.withdraws_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: withdraws_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.withdraws_id_seq OWNED BY public.withdraws.id;


--
-- Name: block_numbers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.block_numbers ALTER COLUMN id SET DEFAULT nextval('public.block_numbers_id_seq'::regclass);


--
-- Name: blockchain_addresses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_addresses ALTER COLUMN id SET DEFAULT nextval('public.blockchain_addresses_id_seq'::regclass);


--
-- Name: blockchain_currencies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_currencies ALTER COLUMN id SET DEFAULT nextval('public.blockchain_currencies_id_seq'::regclass);


--
-- Name: blockchain_transactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_transactions ALTER COLUMN id SET DEFAULT nextval('public.blockchain_transactions_id_seq'::regclass);


--
-- Name: blockchains id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchains ALTER COLUMN id SET DEFAULT nextval('public.blockchains_id_seq'::regclass);


--
-- Name: deposit_addresses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deposit_addresses ALTER COLUMN id SET DEFAULT nextval('public.deposit_addresses_id_seq'::regclass);


--
-- Name: deposits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deposits ALTER COLUMN id SET DEFAULT nextval('public.deposits_id_seq'::regclass);


--
-- Name: legacy_transactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_transactions ALTER COLUMN id SET DEFAULT nextval('public.legacy_transactions_id_seq'::regclass);


--
-- Name: members id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members ALTER COLUMN id SET DEFAULT nextval('public.members_id_seq'::regclass);


--
-- Name: wallets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallets ALTER COLUMN id SET DEFAULT nextval('public.wallets_id_seq'::regclass);


--
-- Name: whitelisted_smart_contracts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.whitelisted_smart_contracts ALTER COLUMN id SET DEFAULT nextval('public.whitelisted_smart_contracts_id_seq'::regclass);


--
-- Name: withdraws id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdraws ALTER COLUMN id SET DEFAULT nextval('public.withdraws_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: block_numbers block_numbers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.block_numbers
    ADD CONSTRAINT block_numbers_pkey PRIMARY KEY (id);


--
-- Name: blockchain_addresses blockchain_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_addresses
    ADD CONSTRAINT blockchain_addresses_pkey PRIMARY KEY (id);


--
-- Name: blockchain_currencies blockchain_currencies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_currencies
    ADD CONSTRAINT blockchain_currencies_pkey PRIMARY KEY (id);


--
-- Name: blockchain_transactions blockchain_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_transactions
    ADD CONSTRAINT blockchain_transactions_pkey PRIMARY KEY (id);


--
-- Name: blockchains blockchains_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchains
    ADD CONSTRAINT blockchains_pkey PRIMARY KEY (id);


--
-- Name: currencies currencies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currencies
    ADD CONSTRAINT currencies_pkey PRIMARY KEY (id);


--
-- Name: deposit_addresses deposit_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deposit_addresses
    ADD CONSTRAINT deposit_addresses_pkey PRIMARY KEY (id);


--
-- Name: deposits deposits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deposits
    ADD CONSTRAINT deposits_pkey PRIMARY KEY (id);


--
-- Name: legacy_transactions legacy_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_transactions
    ADD CONSTRAINT legacy_transactions_pkey PRIMARY KEY (id);


--
-- Name: members members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: wallets wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_pkey PRIMARY KEY (id);


--
-- Name: whitelisted_smart_contracts whitelisted_smart_contracts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.whitelisted_smart_contracts
    ADD CONSTRAINT whitelisted_smart_contracts_pkey PRIMARY KEY (id);


--
-- Name: withdraws withdraws_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdraws
    ADD CONSTRAINT withdraws_pkey PRIMARY KEY (id);


--
-- Name: deposit_addresses_member_blockchain_parent_blockchain_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX deposit_addresses_member_blockchain_parent_blockchain_currency ON public.deposit_addresses USING btree (member_id, blockchain_id, parent_id, blockchain_currency_id) WHERE ((parent_id IS NOT NULL) AND (archived_at IS NULL));


--
-- Name: index_block_numbers_on_blockchain_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_block_numbers_on_blockchain_id ON public.block_numbers USING btree (blockchain_id);


--
-- Name: index_block_numbers_on_blockchain_id_and_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_block_numbers_on_blockchain_id_and_number ON public.block_numbers USING btree (blockchain_id, number);


--
-- Name: index_blockchain_addresses_on_address_and_address_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_blockchain_addresses_on_address_and_address_type ON public.blockchain_addresses USING btree (address, address_type);


--
-- Name: index_blockchain_currencies_on_blockchain_id_and_currency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_blockchain_currencies_on_blockchain_id_and_currency_id ON public.blockchain_currencies USING btree (blockchain_id, currency_id);


--
-- Name: index_blockchain_currencies_on_currency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blockchain_currencies_on_currency_id ON public.blockchain_currencies USING btree (currency_id);


--
-- Name: index_blockchains_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_blockchains_on_key ON public.blockchains USING btree (key);


--
-- Name: index_deposit_addresses_on_blockchain_currency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposit_addresses_on_blockchain_currency_id ON public.deposit_addresses USING btree (blockchain_currency_id);


--
-- Name: index_deposit_addresses_on_blockchain_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposit_addresses_on_blockchain_id ON public.deposit_addresses USING btree (blockchain_id);


--
-- Name: index_deposit_addresses_on_blockchain_id_and_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_deposit_addresses_on_blockchain_id_and_address ON public.deposit_addresses USING btree (blockchain_id, address) WHERE (address IS NOT NULL);


--
-- Name: index_deposit_addresses_on_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposit_addresses_on_member_id ON public.deposit_addresses USING btree (member_id);


--
-- Name: index_deposit_addresses_on_member_id_and_blockchain_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_deposit_addresses_on_member_id_and_blockchain_id ON public.deposit_addresses USING btree (member_id, blockchain_id) WHERE ((parent_id IS NULL) AND (archived_at IS NULL));


--
-- Name: index_deposit_addresses_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposit_addresses_on_parent_id ON public.deposit_addresses USING btree (parent_id);


--
-- Name: index_deposits_on_blockchain_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_blockchain_id ON public.deposits USING btree (blockchain_id);


--
-- Name: index_deposits_on_currency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_currency_id ON public.deposits USING btree (currency_id);


--
-- Name: index_deposits_on_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_member_id ON public.deposits USING btree (member_id);


--
-- Name: index_legacy_transactions_on_blockchain_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_legacy_transactions_on_blockchain_id ON public.legacy_transactions USING btree (blockchain_id);


--
-- Name: index_legacy_transactions_on_currency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_legacy_transactions_on_currency_id ON public.legacy_transactions USING btree (currency_id);


--
-- Name: index_legacy_transactions_on_txid_and_blockchain_id_and_vout; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_legacy_transactions_on_txid_and_blockchain_id_and_vout ON public.legacy_transactions USING btree (txid, blockchain_id, vout);


--
-- Name: index_members_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_members_on_email ON public.members USING btree (email);


--
-- Name: index_members_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_members_on_uid ON public.members USING btree (uid);


--
-- Name: index_transactions_on_blockchain_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_blockchain_id ON public.blockchain_transactions USING btree (blockchain_id);


--
-- Name: index_transactions_on_blockchain_id_and_from; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_blockchain_id_and_from ON public.blockchain_transactions USING btree (blockchain_id, "from");


--
-- Name: index_transactions_on_blockchain_id_and_kind; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_blockchain_id_and_kind ON public.blockchain_transactions USING btree (blockchain_id, kind);


--
-- Name: index_transactions_on_blockchain_id_and_to; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_blockchain_id_and_to ON public.blockchain_transactions USING btree (blockchain_id, "to");


--
-- Name: index_transactions_on_blockchain_id_and_txid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_transactions_on_blockchain_id_and_txid ON public.blockchain_transactions USING btree (blockchain_id, txid) WHERE (txout IS NULL);


--
-- Name: index_transactions_on_blockchain_id_and_txid_and_txout; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_transactions_on_blockchain_id_and_txid_and_txout ON public.blockchain_transactions USING btree (blockchain_id, txid, txout) WHERE (txout IS NOT NULL);


--
-- Name: index_transactions_on_currency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_currency_id ON public.blockchain_transactions USING btree (currency_id);


--
-- Name: index_transactions_on_fee_currency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_fee_currency_id ON public.blockchain_transactions USING btree (fee_currency_id);


--
-- Name: index_transactions_on_reference_type_and_reference_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_reference_type_and_reference_id ON public.blockchain_transactions USING btree (reference_type, reference_id);


--
-- Name: index_transactions_on_txid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_txid ON public.blockchain_transactions USING btree (txid);


--
-- Name: index_wallets_on_blockchain_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wallets_on_blockchain_id ON public.wallets USING btree (blockchain_id);


--
-- Name: index_whitelisted_smart_contracts_on_blockchain_id_and_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_whitelisted_smart_contracts_on_blockchain_id_and_address ON public.whitelisted_smart_contracts USING btree (blockchain_id, address);


--
-- Name: index_withdraws_on_blockchain_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_withdraws_on_blockchain_id ON public.withdraws USING btree (blockchain_id);


--
-- Name: blockchain_transactions fk_rails_06e3dc9eff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_transactions
    ADD CONSTRAINT fk_rails_06e3dc9eff FOREIGN KEY (fee_currency_id) REFERENCES public.currencies(id);


--
-- Name: deposit_addresses fk_rails_72c93a6bbc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deposit_addresses
    ADD CONSTRAINT fk_rails_72c93a6bbc FOREIGN KEY (parent_id) REFERENCES public.deposit_addresses(id);


--
-- Name: blockchain_currencies fk_rails_7b9177edd7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_currencies
    ADD CONSTRAINT fk_rails_7b9177edd7 FOREIGN KEY (blockchain_id) REFERENCES public.blockchains(id);


--
-- Name: block_numbers fk_rails_872254c4f9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.block_numbers
    ADD CONSTRAINT fk_rails_872254c4f9 FOREIGN KEY (blockchain_id) REFERENCES public.blockchains(id);


--
-- Name: legacy_transactions fk_rails_a0da725b4c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_transactions
    ADD CONSTRAINT fk_rails_a0da725b4c FOREIGN KEY (blockchain_id) REFERENCES public.blockchains(id);


--
-- Name: blockchain_transactions fk_rails_a78857d706; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_transactions
    ADD CONSTRAINT fk_rails_a78857d706 FOREIGN KEY (currency_id) REFERENCES public.currencies(id);


--
-- Name: legacy_transactions fk_rails_b4c7ab2c58; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.legacy_transactions
    ADD CONSTRAINT fk_rails_b4c7ab2c58 FOREIGN KEY (currency_id) REFERENCES public.currencies(id);


--
-- Name: blockchain_currencies fk_rails_c890abe125; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_currencies
    ADD CONSTRAINT fk_rails_c890abe125 FOREIGN KEY (parent_id) REFERENCES public.blockchain_currencies(id);


--
-- Name: blockchain_transactions fk_rails_e815a7042b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_transactions
    ADD CONSTRAINT fk_rails_e815a7042b FOREIGN KEY (blockchain_id) REFERENCES public.blockchains(id);


--
-- Name: blockchain_currencies fk_rails_fac9f73ca6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_currencies
    ADD CONSTRAINT fk_rails_fac9f73ca6 FOREIGN KEY (currency_id) REFERENCES public.currencies(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20220217043817'),
('20220217043822'),
('20220217043828'),
('20220217043832'),
('20220217043844'),
('20220217044710'),
('20220217125641'),
('20220225081905'),
('20220228111350'),
('20220302132057'),
('20220303124031'),
('20220305135827'),
('20220305141037'),
('20220309054415'),
('20220309135513'),
('20220310150719'),
('20220311093544'),
('20220314131954'),
('20220314153417'),
('20220324101216'),
('20220325130434'),
('20220325135112'),
('20220329154222'),
('20220329154235'),
('20220331112119'),
('20220404151721'),
('20220404152746');


