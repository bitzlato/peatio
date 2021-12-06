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


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: compact_orders(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.compact_orders(min_date date, max_date date, OUT pointer integer, OUT counter integer) RETURNS record
    LANGUAGE plpgsql
    AS $$
    BEGIN
        -- Temporary liabilities table
        CREATE TABLE IF NOT EXISTS liabilities_tmp AS TABLE liabilities;

        -- Copy liabilities to tmp
        INSERT INTO liabilities_tmp SELECT * FROM liabilities
        WHERE LOWER(reference_type) = LOWER('Order') AND created_at BETWEEN min_date AND max_date;

        -- Set counter and pointer vars
        get diagnostics counter = row_count;
        SELECT to_char(max_date, 'YYYYMMDD')::integer from liabilities INTO pointer;

        -- Delete liabilities to compact
        DELETE FROM liabilities WHERE LOWER(reference_type) = LOWER('Order') AND created_at BETWEEN min_date AND max_date;

        CREATE SEQUENCE liabilities_tmp_id START 1 INCREMENT 1 MINVALUE 1 OWNED BY liabilities_tmp.id;

        INSERT INTO liabilities
        SELECT nextval('liabilities_tmp_id') + (select max(id) + 1 from liabilities), code, currency_id, member_id, 'CompactOrders',
        to_char(max_date, 'YYYYMMDD')::integer, SUM(debit)::decimal, SUM(credit)::decimal, DATE(created_at), NOW()::date FROM liabilities_tmp
        WHERE LOWER(reference_type) = LOWER('Order') AND created_at BETWEEN min_date AND max_date
        GROUP BY code, currency_id, member_id, DATE(created_at);

        DROP SEQUENCE IF EXISTS liabilities_tmp_id;
        DROP TABLE liabilities_tmp;
    END
    $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    member_id bigint NOT NULL,
    currency_id character varying(10) NOT NULL,
    balance numeric(36,18) DEFAULT 0 NOT NULL,
    locked numeric(36,18) DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: adjustments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adjustments (
    id bigint NOT NULL,
    reason character varying NOT NULL,
    description text NOT NULL,
    creator_id bigint NOT NULL,
    validator_id bigint,
    amount numeric(36,18) NOT NULL,
    asset_account_code smallint NOT NULL,
    receiving_account_number character varying(64) NOT NULL,
    currency_id character varying NOT NULL,
    category smallint NOT NULL,
    state smallint NOT NULL,
    created_at timestamp(3) without time zone NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL
);


--
-- Name: adjustments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.adjustments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: adjustments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.adjustments_id_seq OWNED BY public.adjustments.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assets (
    id bigint NOT NULL,
    code integer NOT NULL,
    currency_id character varying NOT NULL,
    reference_type character varying,
    reference_id bigint,
    debit numeric(36,18) DEFAULT 0 NOT NULL,
    credit numeric(36,18) DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assets_id_seq OWNED BY public.assets.id;


--
-- Name: beneficiaries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.beneficiaries (
    id bigint NOT NULL,
    member_id bigint NOT NULL,
    currency_id character varying(10) NOT NULL,
    name character varying(64) NOT NULL,
    description character varying DEFAULT ''::character varying,
    pin integer NOT NULL,
    state smallint DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    sent_at timestamp without time zone,
    data_encrypted character varying(1024)
);


--
-- Name: beneficiaries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.beneficiaries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: beneficiaries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.beneficiaries_id_seq OWNED BY public.beneficiaries.id;


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
    private_key_hex_encrypted character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
-- Name: blockchain_approvals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blockchain_approvals (
    id bigint NOT NULL,
    currency_id character varying(10) NOT NULL,
    txid public.citext NOT NULL,
    owner_address public.citext NOT NULL,
    spender_address public.citext NOT NULL,
    block_number integer,
    status integer DEFAULT 0 NOT NULL,
    options json,
    blockchain_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: blockchain_approvals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blockchain_approvals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blockchain_approvals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blockchain_approvals_id_seq OWNED BY public.blockchain_approvals.id;


--
-- Name: blockchain_nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blockchain_nodes (
    id bigint NOT NULL,
    blockchain_id bigint,
    client character varying NOT NULL,
    server_encrypted character varying(1024),
    latest_block_number bigint,
    server_touched_at timestamp without time zone,
    is_public boolean DEFAULT false NOT NULL,
    has_accounts boolean DEFAULT false NOT NULL,
    use_for_withdraws boolean DEFAULT false NOT NULL,
    archived_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: blockchain_nodes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blockchain_nodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blockchain_nodes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blockchain_nodes_id_seq OWNED BY public.blockchain_nodes.id;


--
-- Name: blockchains; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blockchains (
    key character varying NOT NULL,
    name character varying,
    height bigint NOT NULL,
    explorer_address character varying,
    explorer_transaction character varying,
    min_confirmations integer DEFAULT 6 NOT NULL,
    status character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    server_encrypted character varying(1024),
    id bigint NOT NULL,
    enable_invoice boolean DEFAULT false NOT NULL,
    explorer_contract_address character varying,
    client character varying NOT NULL,
    client_options jsonb DEFAULT '{}'::jsonb NOT NULL,
    height_updated_at timestamp without time zone,
    client_version character varying,
    high_transaction_price_at timestamp without time zone,
    address_type character varying,
    disable_collection boolean DEFAULT false NOT NULL,
    allowance_enabled boolean DEFAULT false NOT NULL,
    chain_id integer
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
    id character varying(10) NOT NULL,
    type character varying(30) DEFAULT 'coin'::character varying NOT NULL,
    withdraw_limit_24h numeric(36,18) DEFAULT 0 NOT NULL,
    options json,
    visible boolean DEFAULT true NOT NULL,
    "precision" smallint DEFAULT 8 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    withdraw_fee numeric(36,18) DEFAULT 0 NOT NULL,
    deposit_fee numeric(36,18) DEFAULT 0 NOT NULL,
    icon_url character varying,
    min_deposit_amount numeric(36,18) DEFAULT 0 NOT NULL,
    withdraw_limit_72h numeric(36,18) DEFAULT 0 NOT NULL,
    min_collection_amount numeric(36,18) DEFAULT 0 NOT NULL,
    min_withdraw_amount numeric(36,18) DEFAULT 0 NOT NULL,
    name character varying,
    "position" integer NOT NULL,
    deposit_enabled boolean DEFAULT true NOT NULL,
    withdrawal_enabled boolean DEFAULT true NOT NULL,
    description text,
    homepage character varying,
    price numeric(36,18) DEFAULT 1 NOT NULL,
    parent_id character varying,
    blockchain_id bigint NOT NULL,
    base_factor bigint NOT NULL,
    contract_address character varying
);


--
-- Name: currencies_wallets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.currencies_wallets (
    currency_id character varying,
    wallet_id bigint,
    use_in_balance boolean DEFAULT true NOT NULL
);


--
-- Name: deposit_spreads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deposit_spreads (
    id bigint NOT NULL,
    deposit_id bigint,
    to_address character varying NOT NULL,
    txid character varying NOT NULL,
    currency_id character varying NOT NULL,
    amount numeric NOT NULL,
    meta jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: deposit_spreads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.deposit_spreads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deposit_spreads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.deposit_spreads_id_seq OWNED BY public.deposit_spreads.id;


--
-- Name: deposits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deposits (
    id bigint NOT NULL,
    member_id bigint NOT NULL,
    currency_id character varying(10) NOT NULL,
    amount numeric(36,18) NOT NULL,
    fee numeric(36,18) NOT NULL,
    txid public.citext,
    aasm_state character varying(30) NOT NULL,
    created_at timestamp(3) without time zone NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL,
    completed_at timestamp(3) without time zone,
    type character varying(30) NOT NULL,
    txout integer,
    tid public.citext NOT NULL,
    address character varying(95),
    block_number integer,
    from_addresses text,
    transfer_type integer,
    data json,
    invoice_id character varying,
    error json,
    blockchain_id bigint NOT NULL,
    invoice_expires_at timestamp without time zone,
    is_locked boolean DEFAULT false NOT NULL
);


--
-- Name: deposits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.deposits_id_seq
    AS integer
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
-- Name: engines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.engines (
    id bigint NOT NULL,
    name character varying NOT NULL,
    driver character varying NOT NULL,
    uid character varying,
    url character varying,
    key_encrypted character varying,
    secret_encrypted character varying,
    data_encrypted character varying(1024),
    state integer DEFAULT 1 NOT NULL
);


--
-- Name: engines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.engines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: engines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.engines_id_seq OWNED BY public.engines.id;


--
-- Name: expenses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.expenses (
    id bigint NOT NULL,
    code integer NOT NULL,
    currency_id character varying NOT NULL,
    reference_type character varying,
    reference_id bigint,
    debit numeric(36,18) DEFAULT 0 NOT NULL,
    credit numeric(36,18) DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: expenses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.expenses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: expenses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.expenses_id_seq OWNED BY public.expenses.id;


--
-- Name: gas_refuels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gas_refuels (
    id bigint NOT NULL,
    blockchain_id bigint NOT NULL,
    txid character varying NOT NULL,
    gas_wallet_address character varying NOT NULL,
    target_address character varying NOT NULL,
    amount bigint NOT NULL,
    status character varying NOT NULL,
    gas_price bigint NOT NULL,
    gas_limit bigint NOT NULL,
    gas_factor bigint DEFAULT 1 NOT NULL,
    result_transaction jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: gas_refuels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gas_refuels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gas_refuels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gas_refuels_id_seq OWNED BY public.gas_refuels.id;


--
-- Name: internal_transfers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.internal_transfers (
    id bigint NOT NULL,
    currency_id character varying NOT NULL,
    amount numeric(36,18) NOT NULL,
    sender_id bigint NOT NULL,
    receiver_id bigint NOT NULL,
    state integer DEFAULT 1 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: internal_transfers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.internal_transfers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: internal_transfers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.internal_transfers_id_seq OWNED BY public.internal_transfers.id;


--
-- Name: jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.jobs (
    id bigint NOT NULL,
    name character varying NOT NULL,
    pointer integer,
    counter integer,
    data json,
    error_code smallint DEFAULT 255 NOT NULL,
    error_message character varying,
    started_at timestamp without time zone,
    finished_at timestamp without time zone
);


--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.jobs_id_seq OWNED BY public.jobs.id;


--
-- Name: liabilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.liabilities (
    id bigint NOT NULL,
    code integer NOT NULL,
    currency_id character varying NOT NULL,
    member_id bigint,
    reference_type character varying,
    reference_id bigint,
    debit numeric(36,18) DEFAULT 0 NOT NULL,
    credit numeric(36,18) DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: liabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.liabilities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: liabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.liabilities_id_seq OWNED BY public.liabilities.id;


--
-- Name: markets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.markets (
    id bigint NOT NULL,
    symbol character varying(20) NOT NULL,
    type character varying DEFAULT 'spot'::character varying NOT NULL,
    base_unit character varying(10) NOT NULL,
    quote_unit character varying(10) NOT NULL,
    engine_id bigint NOT NULL,
    amount_precision smallint DEFAULT 4 NOT NULL,
    price_precision smallint DEFAULT 4 NOT NULL,
    min_price numeric(36,18) DEFAULT 0 NOT NULL,
    max_price numeric(36,18) DEFAULT 0 NOT NULL,
    min_amount numeric(36,18) DEFAULT 0 NOT NULL,
    "position" integer NOT NULL,
    data json,
    state character varying(32) DEFAULT 'enabled'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: markets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.markets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: markets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.markets_id_seq OWNED BY public.markets.id;


--
-- Name: member_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.member_groups (
    id bigint NOT NULL,
    key character varying(25) NOT NULL,
    open_orders_limit integer DEFAULT 1 NOT NULL,
    rates_limits jsonb DEFAULT '{"minut": 100, "second": 10}'::jsonb NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: member_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.member_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: member_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.member_groups_id_seq OWNED BY public.member_groups.id;


--
-- Name: members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.members (
    id bigint NOT NULL,
    email character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    uid character varying(32) NOT NULL,
    level integer NOT NULL,
    role character varying(16) NOT NULL,
    state character varying(16) NOT NULL,
    "group" character varying(32) DEFAULT 'any'::character varying NOT NULL,
    username character varying,
    withdraw_disabled_at timestamp without time zone,
    withdraw_disabled_comment character varying,
    withdraw_disabled_by integer
);


--
-- Name: members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.members_id_seq
    AS integer
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
-- Name: operations_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operations_accounts (
    id bigint NOT NULL,
    code integer NOT NULL,
    type character varying(10) NOT NULL,
    kind character varying(30) NOT NULL,
    currency_type character varying(10) NOT NULL,
    description character varying(100),
    scope character varying(10) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: operations_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operations_accounts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operations_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operations_accounts_id_seq OWNED BY public.operations_accounts.id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders (
    id bigint NOT NULL,
    bid character varying(10) NOT NULL,
    ask character varying(10) NOT NULL,
    market_id character varying(20) NOT NULL,
    price numeric(36,18),
    volume numeric(36,18) NOT NULL,
    origin_volume numeric(36,18) NOT NULL,
    state integer NOT NULL,
    type character varying(8) NOT NULL,
    member_id bigint NOT NULL,
    created_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    ord_type character varying(30) NOT NULL,
    locked numeric(36,18) DEFAULT 0 NOT NULL,
    origin_locked numeric(36,18) DEFAULT 0 NOT NULL,
    funds_received numeric(36,18) DEFAULT 0,
    trades_count integer DEFAULT 0 NOT NULL,
    maker_fee numeric(19,18) DEFAULT 0 NOT NULL,
    taker_fee numeric(19,18) DEFAULT 0 NOT NULL,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    remote_id character varying,
    market_type character varying DEFAULT 'spot'::character varying NOT NULL,
    trigger_price numeric(36,18),
    triggered_at timestamp without time zone,
    canceling_at timestamp without time zone
);


--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- Name: payment_addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_addresses (
    id bigint NOT NULL,
    address character varying(95),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    secret_encrypted character varying(255),
    details_encrypted character varying(1024),
    member_id bigint,
    remote boolean DEFAULT false NOT NULL,
    blockchain_id bigint NOT NULL,
    balances jsonb DEFAULT '{}'::jsonb,
    balances_updated_at timestamp without time zone,
    collection_state character varying DEFAULT 'none'::character varying NOT NULL,
    collected_at timestamp without time zone,
    gas_refueled_at timestamp without time zone,
    last_transfer_try_at timestamp without time zone,
    last_transfer_status character varying,
    enqueued_generation_at timestamp without time zone,
    archived_at timestamp without time zone
);


--
-- Name: payment_addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payment_addresses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payment_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payment_addresses_id_seq OWNED BY public.payment_addresses.id;


--
-- Name: refunds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.refunds (
    id bigint NOT NULL,
    deposit_id bigint NOT NULL,
    state character varying(30) NOT NULL,
    address character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: refunds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.refunds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refunds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.refunds_id_seq OWNED BY public.refunds.id;


--
-- Name: revenues; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.revenues (
    id bigint NOT NULL,
    code integer NOT NULL,
    currency_id character varying NOT NULL,
    reference_type character varying,
    reference_id bigint,
    debit numeric(36,18) DEFAULT 0 NOT NULL,
    credit numeric(36,18) DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    member_id bigint
);


--
-- Name: revenues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.revenues_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: revenues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.revenues_id_seq OWNED BY public.revenues.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: stats_member_pnl; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stats_member_pnl (
    id bigint NOT NULL,
    member_id bigint NOT NULL,
    pnl_currency_id character varying(10) NOT NULL,
    currency_id character varying(10) NOT NULL,
    total_credit numeric(50,18) DEFAULT 0,
    total_credit_fees numeric(50,18) DEFAULT 0,
    total_debit_fees numeric(50,18) DEFAULT 0,
    total_debit numeric(50,18) DEFAULT 0,
    total_credit_value numeric(50,18) DEFAULT 0,
    total_debit_value numeric(50,18) DEFAULT 0,
    total_balance_value numeric(50,18) DEFAULT 0,
    average_balance_price numeric(50,18) DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: stats_member_pnl_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stats_member_pnl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stats_member_pnl_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stats_member_pnl_id_seq OWNED BY public.stats_member_pnl.id;


--
-- Name: stats_member_pnl_idx; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stats_member_pnl_idx (
    id bigint NOT NULL,
    pnl_currency_id character varying(10) NOT NULL,
    currency_id character varying(10) NOT NULL,
    reference_type character varying(255) NOT NULL,
    last_id bigint,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: stats_member_pnl_idx_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stats_member_pnl_idx_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stats_member_pnl_idx_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stats_member_pnl_idx_id_seq OWNED BY public.stats_member_pnl_idx.id;


--
-- Name: swap_orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.swap_orders (
    id bigint NOT NULL,
    from_unit character varying NOT NULL,
    to_unit character varying NOT NULL,
    order_id bigint,
    member_id bigint NOT NULL,
    market_id character varying(20) NOT NULL,
    state integer NOT NULL,
    from_volume numeric(36,18) NOT NULL,
    to_volume numeric(36,18) NOT NULL,
    request_unit character varying NOT NULL,
    request_volume numeric(36,18) NOT NULL,
    request_price numeric(36,18) NOT NULL,
    inverse_price numeric(36,18) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: swap_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.swap_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: swap_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.swap_orders_id_seq OWNED BY public.swap_orders.id;


--
-- Name: trades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trades (
    id bigint NOT NULL,
    price numeric(36,18) NOT NULL,
    amount numeric(36,18) NOT NULL,
    maker_order_id bigint NOT NULL,
    taker_order_id bigint NOT NULL,
    market_id character varying(20) NOT NULL,
    created_at timestamp(3) without time zone NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL,
    maker_id bigint NOT NULL,
    taker_id bigint NOT NULL,
    total numeric(36,18) DEFAULT 0 NOT NULL,
    taker_type character varying(20) DEFAULT ''::character varying NOT NULL,
    market_type character varying DEFAULT 'spot'::character varying NOT NULL
);


--
-- Name: trades_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trades_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trades_id_seq OWNED BY public.trades.id;


--
-- Name: trading_fees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trading_fees (
    id bigint NOT NULL,
    market_id character varying(20) DEFAULT 'any'::character varying NOT NULL,
    "group" character varying(32) DEFAULT 'any'::character varying NOT NULL,
    maker numeric(7,6) DEFAULT 0 NOT NULL,
    taker numeric(7,6) DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    market_type character varying DEFAULT 'spot'::character varying NOT NULL
);


--
-- Name: trading_fees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trading_fees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trading_fees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trading_fees_id_seq OWNED BY public.trading_fees.id;


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transactions (
    id bigint NOT NULL,
    currency_id character varying NOT NULL,
    reference_type character varying,
    reference_id bigint,
    txid character varying,
    from_address character varying,
    to_address character varying,
    amount numeric(36,18) DEFAULT 0 NOT NULL,
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
    direction integer
);


--
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transactions_id_seq OWNED BY public.transactions.id;


--
-- Name: transfers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transfers (
    id bigint NOT NULL,
    key character varying(30) NOT NULL,
    description character varying(255) DEFAULT ''::character varying,
    created_at timestamp(3) without time zone NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL,
    category smallint NOT NULL
);


--
-- Name: transfers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transfers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transfers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transfers_id_seq OWNED BY public.transfers.id;


--
-- Name: wallets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wallets (
    id bigint NOT NULL,
    name character varying(64),
    address character varying NOT NULL,
    status character varying(32),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    max_balance numeric(36,18) DEFAULT 0 NOT NULL,
    kind integer NOT NULL,
    settings_encrypted character varying(1024),
    balance jsonb,
    plain_settings json,
    enable_invoice boolean DEFAULT false NOT NULL,
    blockchain_id bigint NOT NULL,
    use_as_fee_source boolean DEFAULT false NOT NULL,
    balance_updated_at timestamp without time zone
);


--
-- Name: wallets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wallets_id_seq
    AS integer
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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    blockchain_id bigint NOT NULL
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
-- Name: withdraw_limits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.withdraw_limits (
    id bigint NOT NULL,
    "group" character varying(32) DEFAULT 'any'::character varying NOT NULL,
    kyc_level character varying(32) DEFAULT 'any'::character varying NOT NULL,
    limit_24_hour numeric(36,18) DEFAULT 0 NOT NULL,
    limit_1_month numeric(36,18) DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: withdraw_limits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.withdraw_limits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: withdraw_limits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.withdraw_limits_id_seq OWNED BY public.withdraw_limits.id;


--
-- Name: withdraws; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.withdraws (
    id bigint NOT NULL,
    member_id bigint NOT NULL,
    currency_id character varying(10) NOT NULL,
    amount numeric(36,18) NOT NULL,
    fee numeric(36,18) NOT NULL,
    created_at timestamp(3) without time zone NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL,
    completed_at timestamp(3) without time zone,
    txid public.citext,
    aasm_state character varying(30) NOT NULL,
    sum numeric(36,18) NOT NULL,
    type character varying(30) NOT NULL,
    tid public.citext NOT NULL,
    rid character varying(256) NOT NULL,
    block_number integer,
    note character varying(256),
    error json,
    beneficiary_id bigint,
    transfer_type integer,
    metadata json,
    remote_id character varying,
    blockchain_id bigint NOT NULL,
    tx_dump jsonb,
    is_locked boolean DEFAULT false NOT NULL
);


--
-- Name: withdraws_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.withdraws_id_seq
    AS integer
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
-- Name: adjustments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjustments ALTER COLUMN id SET DEFAULT nextval('public.adjustments_id_seq'::regclass);


--
-- Name: assets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets ALTER COLUMN id SET DEFAULT nextval('public.assets_id_seq'::regclass);


--
-- Name: beneficiaries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beneficiaries ALTER COLUMN id SET DEFAULT nextval('public.beneficiaries_id_seq'::regclass);


--
-- Name: block_numbers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.block_numbers ALTER COLUMN id SET DEFAULT nextval('public.block_numbers_id_seq'::regclass);


--
-- Name: blockchain_addresses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_addresses ALTER COLUMN id SET DEFAULT nextval('public.blockchain_addresses_id_seq'::regclass);


--
-- Name: blockchain_approvals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_approvals ALTER COLUMN id SET DEFAULT nextval('public.blockchain_approvals_id_seq'::regclass);


--
-- Name: blockchain_nodes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_nodes ALTER COLUMN id SET DEFAULT nextval('public.blockchain_nodes_id_seq'::regclass);


--
-- Name: blockchains id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchains ALTER COLUMN id SET DEFAULT nextval('public.blockchains_id_seq'::regclass);


--
-- Name: deposit_spreads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deposit_spreads ALTER COLUMN id SET DEFAULT nextval('public.deposit_spreads_id_seq'::regclass);


--
-- Name: deposits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deposits ALTER COLUMN id SET DEFAULT nextval('public.deposits_id_seq'::regclass);


--
-- Name: engines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.engines ALTER COLUMN id SET DEFAULT nextval('public.engines_id_seq'::regclass);


--
-- Name: expenses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses ALTER COLUMN id SET DEFAULT nextval('public.expenses_id_seq'::regclass);


--
-- Name: gas_refuels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gas_refuels ALTER COLUMN id SET DEFAULT nextval('public.gas_refuels_id_seq'::regclass);


--
-- Name: internal_transfers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.internal_transfers ALTER COLUMN id SET DEFAULT nextval('public.internal_transfers_id_seq'::regclass);


--
-- Name: jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs ALTER COLUMN id SET DEFAULT nextval('public.jobs_id_seq'::regclass);


--
-- Name: liabilities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liabilities ALTER COLUMN id SET DEFAULT nextval('public.liabilities_id_seq'::regclass);


--
-- Name: markets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.markets ALTER COLUMN id SET DEFAULT nextval('public.markets_id_seq'::regclass);


--
-- Name: member_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_groups ALTER COLUMN id SET DEFAULT nextval('public.member_groups_id_seq'::regclass);


--
-- Name: members id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members ALTER COLUMN id SET DEFAULT nextval('public.members_id_seq'::regclass);


--
-- Name: operations_accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operations_accounts ALTER COLUMN id SET DEFAULT nextval('public.operations_accounts_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- Name: payment_addresses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_addresses ALTER COLUMN id SET DEFAULT nextval('public.payment_addresses_id_seq'::regclass);


--
-- Name: refunds id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refunds ALTER COLUMN id SET DEFAULT nextval('public.refunds_id_seq'::regclass);


--
-- Name: revenues id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.revenues ALTER COLUMN id SET DEFAULT nextval('public.revenues_id_seq'::regclass);


--
-- Name: stats_member_pnl id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stats_member_pnl ALTER COLUMN id SET DEFAULT nextval('public.stats_member_pnl_id_seq'::regclass);


--
-- Name: stats_member_pnl_idx id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stats_member_pnl_idx ALTER COLUMN id SET DEFAULT nextval('public.stats_member_pnl_idx_id_seq'::regclass);


--
-- Name: swap_orders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.swap_orders ALTER COLUMN id SET DEFAULT nextval('public.swap_orders_id_seq'::regclass);


--
-- Name: trades id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trades ALTER COLUMN id SET DEFAULT nextval('public.trades_id_seq'::regclass);


--
-- Name: trading_fees id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trading_fees ALTER COLUMN id SET DEFAULT nextval('public.trading_fees_id_seq'::regclass);


--
-- Name: transactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions ALTER COLUMN id SET DEFAULT nextval('public.transactions_id_seq'::regclass);


--
-- Name: transfers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfers ALTER COLUMN id SET DEFAULT nextval('public.transfers_id_seq'::regclass);


--
-- Name: wallets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallets ALTER COLUMN id SET DEFAULT nextval('public.wallets_id_seq'::regclass);


--
-- Name: whitelisted_smart_contracts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.whitelisted_smart_contracts ALTER COLUMN id SET DEFAULT nextval('public.whitelisted_smart_contracts_id_seq'::regclass);


--
-- Name: withdraw_limits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdraw_limits ALTER COLUMN id SET DEFAULT nextval('public.withdraw_limits_id_seq'::regclass);


--
-- Name: withdraws id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdraws ALTER COLUMN id SET DEFAULT nextval('public.withdraws_id_seq'::regclass);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (currency_id, member_id);


--
-- Name: adjustments adjustments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjustments
    ADD CONSTRAINT adjustments_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: assets assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_pkey PRIMARY KEY (id);


--
-- Name: beneficiaries beneficiaries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beneficiaries
    ADD CONSTRAINT beneficiaries_pkey PRIMARY KEY (id);


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
-- Name: blockchain_approvals blockchain_approvals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_approvals
    ADD CONSTRAINT blockchain_approvals_pkey PRIMARY KEY (id);


--
-- Name: blockchain_nodes blockchain_nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_nodes
    ADD CONSTRAINT blockchain_nodes_pkey PRIMARY KEY (id);


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
-- Name: deposit_spreads deposit_spreads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deposit_spreads
    ADD CONSTRAINT deposit_spreads_pkey PRIMARY KEY (id);


--
-- Name: deposits deposits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deposits
    ADD CONSTRAINT deposits_pkey PRIMARY KEY (id);


--
-- Name: engines engines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.engines
    ADD CONSTRAINT engines_pkey PRIMARY KEY (id);


--
-- Name: expenses expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_pkey PRIMARY KEY (id);


--
-- Name: gas_refuels gas_refuels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gas_refuels
    ADD CONSTRAINT gas_refuels_pkey PRIMARY KEY (id);


--
-- Name: internal_transfers internal_transfers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.internal_transfers
    ADD CONSTRAINT internal_transfers_pkey PRIMARY KEY (id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: liabilities liabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liabilities
    ADD CONSTRAINT liabilities_pkey PRIMARY KEY (id);


--
-- Name: markets markets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.markets
    ADD CONSTRAINT markets_pkey PRIMARY KEY (id);


--
-- Name: member_groups member_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_groups
    ADD CONSTRAINT member_groups_pkey PRIMARY KEY (id);


--
-- Name: members members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_pkey PRIMARY KEY (id);


--
-- Name: operations_accounts operations_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operations_accounts
    ADD CONSTRAINT operations_accounts_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: payment_addresses payment_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_addresses
    ADD CONSTRAINT payment_addresses_pkey PRIMARY KEY (id);


--
-- Name: refunds refunds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT refunds_pkey PRIMARY KEY (id);


--
-- Name: revenues revenues_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.revenues
    ADD CONSTRAINT revenues_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: stats_member_pnl_idx stats_member_pnl_idx_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stats_member_pnl_idx
    ADD CONSTRAINT stats_member_pnl_idx_pkey PRIMARY KEY (id);


--
-- Name: stats_member_pnl stats_member_pnl_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stats_member_pnl
    ADD CONSTRAINT stats_member_pnl_pkey PRIMARY KEY (id);


--
-- Name: swap_orders swap_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.swap_orders
    ADD CONSTRAINT swap_orders_pkey PRIMARY KEY (id);


--
-- Name: trades trades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trades
    ADD CONSTRAINT trades_pkey PRIMARY KEY (id);


--
-- Name: trading_fees trading_fees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trading_fees
    ADD CONSTRAINT trading_fees_pkey PRIMARY KEY (id);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: transfers transfers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfers
    ADD CONSTRAINT transfers_pkey PRIMARY KEY (id);


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
-- Name: withdraw_limits withdraw_limits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdraw_limits
    ADD CONSTRAINT withdraw_limits_pkey PRIMARY KEY (id);


--
-- Name: withdraws withdraws_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdraws
    ADD CONSTRAINT withdraws_pkey PRIMARY KEY (id);


--
-- Name: index_accounts_on_currency_id_and_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accounts_on_currency_id_and_member_id ON public.accounts USING btree (currency_id, member_id);


--
-- Name: index_accounts_on_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_member_id ON public.accounts USING btree (member_id);


--
-- Name: index_adjustments_on_currency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_adjustments_on_currency_id ON public.adjustments USING btree (currency_id);


--
-- Name: index_adjustments_on_currency_id_and_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_adjustments_on_currency_id_and_state ON public.adjustments USING btree (currency_id, state);


--
-- Name: index_assets_on_currency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assets_on_currency_id ON public.assets USING btree (currency_id);


--
-- Name: index_assets_on_reference_type_and_reference_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assets_on_reference_type_and_reference_id ON public.assets USING btree (reference_type, reference_id);


--
-- Name: index_beneficiaries_on_currency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_beneficiaries_on_currency_id ON public.beneficiaries USING btree (currency_id);


--
-- Name: index_beneficiaries_on_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_beneficiaries_on_member_id ON public.beneficiaries USING btree (member_id);


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
-- Name: index_blockchain_approvals_on_blockchain_id_and_txid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_blockchain_approvals_on_blockchain_id_and_txid ON public.blockchain_approvals USING btree (blockchain_id, txid);


--
-- Name: index_blockchain_approvals_on_currency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blockchain_approvals_on_currency_id ON public.blockchain_approvals USING btree (currency_id);


--
-- Name: index_blockchain_approvals_on_owner_address; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blockchain_approvals_on_owner_address ON public.blockchain_approvals USING btree (owner_address);


--
-- Name: index_blockchain_approvals_on_txid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blockchain_approvals_on_txid ON public.blockchain_approvals USING btree (txid);


--
-- Name: index_blockchain_nodes_on_blockchain_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blockchain_nodes_on_blockchain_id ON public.blockchain_nodes USING btree (blockchain_id);


--
-- Name: index_blockchains_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_blockchains_on_key ON public.blockchains USING btree (key);


--
-- Name: index_blockchains_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blockchains_on_status ON public.blockchains USING btree (status);


--
-- Name: index_currencies_on_blockchain_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_currencies_on_blockchain_id ON public.currencies USING btree (blockchain_id);


--
-- Name: index_currencies_on_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_currencies_on_position ON public.currencies USING btree ("position");


--
-- Name: index_currencies_on_visible; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_currencies_on_visible ON public.currencies USING btree (visible);


--
-- Name: index_currencies_wallets_on_currency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_currencies_wallets_on_currency_id ON public.currencies_wallets USING btree (currency_id);


--
-- Name: index_currencies_wallets_on_currency_id_and_wallet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_currencies_wallets_on_currency_id_and_wallet_id ON public.currencies_wallets USING btree (currency_id, wallet_id);


--
-- Name: index_currencies_wallets_on_wallet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_currencies_wallets_on_wallet_id ON public.currencies_wallets USING btree (wallet_id);


--
-- Name: index_currency_ids_and_last_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_currency_ids_and_last_id ON public.stats_member_pnl_idx USING btree (pnl_currency_id, currency_id, last_id);


--
-- Name: index_currency_ids_and_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_currency_ids_and_member_id ON public.stats_member_pnl USING btree (pnl_currency_id, currency_id, member_id);


--
-- Name: index_currency_ids_and_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_currency_ids_and_type ON public.stats_member_pnl_idx USING btree (pnl_currency_id, currency_id, reference_type);


--
-- Name: index_deposit_spreads_on_deposit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposit_spreads_on_deposit_id ON public.deposit_spreads USING btree (deposit_id);


--
-- Name: index_deposit_spreads_on_txid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_deposit_spreads_on_txid ON public.deposit_spreads USING btree (txid);


--
-- Name: index_deposits_on_aasm_state_and_member_id_and_currency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_aasm_state_and_member_id_and_currency_id ON public.deposits USING btree (aasm_state, member_id, currency_id);


--
-- Name: index_deposits_on_blockchain_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_blockchain_id ON public.deposits USING btree (blockchain_id);


--
-- Name: index_deposits_on_blockchain_id_and_txid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_deposits_on_blockchain_id_and_txid ON public.deposits USING btree (blockchain_id, txid) WHERE (txid IS NOT NULL);


--
-- Name: index_deposits_on_currency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_currency_id ON public.deposits USING btree (currency_id);


--
-- Name: index_deposits_on_currency_id_and_invoice_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_deposits_on_currency_id_and_invoice_id ON public.deposits USING btree (currency_id, invoice_id) WHERE (invoice_id IS NOT NULL);


--
-- Name: index_deposits_on_currency_id_and_txid_and_txout; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_deposits_on_currency_id_and_txid_and_txout ON public.deposits USING btree (currency_id, txid, txout);


--
-- Name: index_deposits_on_member_id_and_txid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_member_id_and_txid ON public.deposits USING btree (member_id, txid);


--
-- Name: index_deposits_on_tid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_tid ON public.deposits USING btree (tid);


--
-- Name: index_deposits_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deposits_on_type ON public.deposits USING btree (type);


--
-- Name: index_expenses_on_currency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_expenses_on_currency_id ON public.expenses USING btree (currency_id);


--
-- Name: index_expenses_on_reference_type_and_reference_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_expenses_on_reference_type_and_reference_id ON public.expenses USING btree (reference_type, reference_id);


--
-- Name: index_gas_refuels_on_blockchain_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gas_refuels_on_blockchain_id ON public.gas_refuels USING btree (blockchain_id);


--
-- Name: index_gas_refuels_on_blockchain_id_and_gas_wallet_address; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gas_refuels_on_blockchain_id_and_gas_wallet_address ON public.gas_refuels USING btree (blockchain_id, gas_wallet_address);


--
-- Name: index_gas_refuels_on_blockchain_id_and_target_address; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gas_refuels_on_blockchain_id_and_target_address ON public.gas_refuels USING btree (blockchain_id, target_address);


--
-- Name: index_gas_refuels_on_blockchain_id_and_txid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_gas_refuels_on_blockchain_id_and_txid ON public.gas_refuels USING btree (blockchain_id, txid);


--
-- Name: index_liabilities_on_currency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_liabilities_on_currency_id ON public.liabilities USING btree (currency_id);


--
-- Name: index_liabilities_on_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_liabilities_on_member_id ON public.liabilities USING btree (member_id);


--
-- Name: index_liabilities_on_reference_type_and_reference_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_liabilities_on_reference_type_and_reference_id ON public.liabilities USING btree (reference_type, reference_id);


--
-- Name: index_markets_on_base_unit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_markets_on_base_unit ON public.markets USING btree (base_unit);


--
-- Name: index_markets_on_base_unit_and_quote_unit_and_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_markets_on_base_unit_and_quote_unit_and_type ON public.markets USING btree (base_unit, quote_unit, type);


--
-- Name: index_markets_on_engine_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_markets_on_engine_id ON public.markets USING btree (engine_id);


--
-- Name: index_markets_on_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_markets_on_position ON public.markets USING btree ("position");


--
-- Name: index_markets_on_quote_unit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_markets_on_quote_unit ON public.markets USING btree (quote_unit);


--
-- Name: index_markets_on_symbol_and_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_markets_on_symbol_and_type ON public.markets USING btree (symbol, type);


--
-- Name: index_member_groups_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_member_groups_on_key ON public.member_groups USING btree (key);


--
-- Name: index_members_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_members_on_email ON public.members USING btree (email);


--
-- Name: index_members_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_members_on_uid ON public.members USING btree (uid);


--
-- Name: index_members_on_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_members_on_username ON public.members USING btree (username) WHERE (username IS NOT NULL);


--
-- Name: index_operations_accounts_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_operations_accounts_on_code ON public.operations_accounts USING btree (code);


--
-- Name: index_operations_accounts_on_currency_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operations_accounts_on_currency_type ON public.operations_accounts USING btree (currency_type);


--
-- Name: index_operations_accounts_on_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operations_accounts_on_scope ON public.operations_accounts USING btree (scope);


--
-- Name: index_operations_accounts_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_operations_accounts_on_type ON public.operations_accounts USING btree (type);


--
-- Name: index_operations_accounts_on_type_and_kind_and_currency_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_operations_accounts_on_type_and_kind_and_currency_type ON public.operations_accounts USING btree (type, kind, currency_type);


--
-- Name: index_orders_on_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_member_id ON public.orders USING btree (member_id);


--
-- Name: index_orders_on_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_state ON public.orders USING btree (state);


--
-- Name: index_orders_on_type_and_market_id_and_market_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_type_and_market_id_and_market_type ON public.orders USING btree (type, market_id, market_type);


--
-- Name: index_orders_on_type_and_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_type_and_member_id ON public.orders USING btree (type, member_id);


--
-- Name: index_orders_on_type_and_state_and_market_id_and_market_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_type_and_state_and_market_id_and_market_type ON public.orders USING btree (type, state, market_id, market_type);


--
-- Name: index_orders_on_type_and_state_and_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_type_and_state_and_member_id ON public.orders USING btree (type, state, member_id);


--
-- Name: index_orders_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_orders_on_updated_at ON public.orders USING btree (updated_at);


--
-- Name: index_payment_addresses_on_blockchain_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_addresses_on_blockchain_id ON public.payment_addresses USING btree (blockchain_id);


--
-- Name: index_payment_addresses_on_blockchain_id_and_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_payment_addresses_on_blockchain_id_and_address ON public.payment_addresses USING btree (blockchain_id, address) WHERE (address IS NOT NULL);


--
-- Name: index_payment_addresses_on_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_addresses_on_member_id ON public.payment_addresses USING btree (member_id);


--
-- Name: index_payment_addresses_on_member_id_and_blockchain_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_payment_addresses_on_member_id_and_blockchain_id ON public.payment_addresses USING btree (member_id, blockchain_id) WHERE (archived_at IS NULL);


--
-- Name: index_refunds_on_deposit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_refunds_on_deposit_id ON public.refunds USING btree (deposit_id);


--
-- Name: index_refunds_on_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_refunds_on_state ON public.refunds USING btree (state);


--
-- Name: index_revenues_on_currency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_revenues_on_currency_id ON public.revenues USING btree (currency_id);


--
-- Name: index_revenues_on_reference_type_and_reference_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_revenues_on_reference_type_and_reference_id ON public.revenues USING btree (reference_type, reference_id);


--
-- Name: index_swap_orders_on_from_unit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_swap_orders_on_from_unit ON public.swap_orders USING btree (from_unit);


--
-- Name: index_swap_orders_on_market_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_swap_orders_on_market_id ON public.swap_orders USING btree (market_id);


--
-- Name: index_swap_orders_on_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_swap_orders_on_member_id ON public.swap_orders USING btree (member_id);


--
-- Name: index_swap_orders_on_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_swap_orders_on_order_id ON public.swap_orders USING btree (order_id);


--
-- Name: index_swap_orders_on_request_unit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_swap_orders_on_request_unit ON public.swap_orders USING btree (request_unit);


--
-- Name: index_swap_orders_on_to_unit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_swap_orders_on_to_unit ON public.swap_orders USING btree (to_unit);


--
-- Name: index_trades_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trades_on_created_at ON public.trades USING btree (created_at);


--
-- Name: index_trades_on_maker_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trades_on_maker_id ON public.trades USING btree (maker_id);


--
-- Name: index_trades_on_maker_id_and_market_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trades_on_maker_id_and_market_type ON public.trades USING btree (maker_id, market_type);


--
-- Name: index_trades_on_maker_id_and_market_type_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trades_on_maker_id_and_market_type_and_created_at ON public.trades USING btree (maker_id, market_type, created_at);


--
-- Name: index_trades_on_maker_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trades_on_maker_order_id ON public.trades USING btree (maker_order_id);


--
-- Name: index_trades_on_taker_id_and_market_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trades_on_taker_id_and_market_type ON public.trades USING btree (taker_id, market_type);


--
-- Name: index_trades_on_taker_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trades_on_taker_order_id ON public.trades USING btree (taker_order_id);


--
-- Name: index_trades_on_taker_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trades_on_taker_type ON public.trades USING btree (taker_type);


--
-- Name: index_trading_fees_on_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trading_fees_on_group ON public.trading_fees USING btree ("group");


--
-- Name: index_trading_fees_on_market_id_and_market_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trading_fees_on_market_id_and_market_type ON public.trading_fees USING btree (market_id, market_type);


--
-- Name: index_trading_fees_on_market_id_and_market_type_and_group; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_trading_fees_on_market_id_and_market_type_and_group ON public.trading_fees USING btree (market_id, market_type, "group");


--
-- Name: index_transactions_on_blockchain_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_blockchain_id ON public.transactions USING btree (blockchain_id);


--
-- Name: index_transactions_on_blockchain_id_and_from; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_blockchain_id_and_from ON public.transactions USING btree (blockchain_id, "from");


--
-- Name: index_transactions_on_blockchain_id_and_kind; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_blockchain_id_and_kind ON public.transactions USING btree (blockchain_id, kind);


--
-- Name: index_transactions_on_blockchain_id_and_to; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_blockchain_id_and_to ON public.transactions USING btree (blockchain_id, "to");


--
-- Name: index_transactions_on_blockchain_id_and_txid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_transactions_on_blockchain_id_and_txid ON public.transactions USING btree (blockchain_id, txid) WHERE (txout IS NULL);


--
-- Name: index_transactions_on_blockchain_id_and_txid_and_txout; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_transactions_on_blockchain_id_and_txid_and_txout ON public.transactions USING btree (blockchain_id, txid, txout) WHERE (txout IS NOT NULL);


--
-- Name: index_transactions_on_currency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_currency_id ON public.transactions USING btree (currency_id);


--
-- Name: index_transactions_on_fee_currency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_fee_currency_id ON public.transactions USING btree (fee_currency_id);


--
-- Name: index_transactions_on_reference_type_and_reference_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_reference_type_and_reference_id ON public.transactions USING btree (reference_type, reference_id);


--
-- Name: index_transactions_on_txid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transactions_on_txid ON public.transactions USING btree (txid);


--
-- Name: index_transfers_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_transfers_on_key ON public.transfers USING btree (key);


--
-- Name: index_wallets_on_blockchain_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wallets_on_blockchain_id ON public.wallets USING btree (blockchain_id);


--
-- Name: index_wallets_on_kind; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wallets_on_kind ON public.wallets USING btree (kind);


--
-- Name: index_wallets_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wallets_on_status ON public.wallets USING btree (status);


--
-- Name: index_whitelisted_smart_contracts_on_blockchain_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_whitelisted_smart_contracts_on_blockchain_id ON public.whitelisted_smart_contracts USING btree (blockchain_id);


--
-- Name: index_whitelisted_smart_contracts_on_blockchain_id_and_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_whitelisted_smart_contracts_on_blockchain_id_and_address ON public.whitelisted_smart_contracts USING btree (blockchain_id, address);


--
-- Name: index_withdraw_limits_on_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_withdraw_limits_on_group ON public.withdraw_limits USING btree ("group");


--
-- Name: index_withdraw_limits_on_group_and_kyc_level; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_withdraw_limits_on_group_and_kyc_level ON public.withdraw_limits USING btree ("group", kyc_level);


--
-- Name: index_withdraw_limits_on_kyc_level; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_withdraw_limits_on_kyc_level ON public.withdraw_limits USING btree (kyc_level);


--
-- Name: index_withdraws_on_aasm_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_withdraws_on_aasm_state ON public.withdraws USING btree (aasm_state);


--
-- Name: index_withdraws_on_blockchain_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_withdraws_on_blockchain_id ON public.withdraws USING btree (blockchain_id);


--
-- Name: index_withdraws_on_currency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_withdraws_on_currency_id ON public.withdraws USING btree (currency_id);


--
-- Name: index_withdraws_on_currency_id_and_txid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_withdraws_on_currency_id_and_txid ON public.withdraws USING btree (currency_id, txid);


--
-- Name: index_withdraws_on_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_withdraws_on_member_id ON public.withdraws USING btree (member_id);


--
-- Name: index_withdraws_on_tid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_withdraws_on_tid ON public.withdraws USING btree (tid);


--
-- Name: index_withdraws_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_withdraws_on_type ON public.withdraws USING btree (type);


--
-- Name: withdraws fk_rails_34ec868d17; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.withdraws
    ADD CONSTRAINT fk_rails_34ec868d17 FOREIGN KEY (blockchain_id) REFERENCES public.blockchains(id);


--
-- Name: gas_refuels fk_rails_74ca68fd87; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gas_refuels
    ADD CONSTRAINT fk_rails_74ca68fd87 FOREIGN KEY (blockchain_id) REFERENCES public.blockchains(id);


--
-- Name: blockchain_nodes fk_rails_86c4fbb9f7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_nodes
    ADD CONSTRAINT fk_rails_86c4fbb9f7 FOREIGN KEY (blockchain_id) REFERENCES public.blockchains(id);


--
-- Name: blockchain_approvals fk_rails_a26b217d2c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blockchain_approvals
    ADD CONSTRAINT fk_rails_a26b217d2c FOREIGN KEY (blockchain_id) REFERENCES public.blockchains(id);


--
-- Name: currencies fk_rails_a7ead03da9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currencies
    ADD CONSTRAINT fk_rails_a7ead03da9 FOREIGN KEY (parent_id) REFERENCES public.currencies(id);


--
-- Name: members fk_rails_cad3e0edf3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT fk_rails_cad3e0edf3 FOREIGN KEY (withdraw_disabled_by) REFERENCES public.members(id);


--
-- Name: deposit_spreads fk_rails_eef3f5807b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deposit_spreads
    ADD CONSTRAINT fk_rails_eef3f5807b FOREIGN KEY (deposit_id) REFERENCES public.deposits(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20180112151205'),
('20180212115002'),
('20180212115751'),
('20180213160501'),
('20180215124645'),
('20180215131129'),
('20180215144645'),
('20180215144646'),
('20180216145412'),
('20180227163417'),
('20180303121013'),
('20180303211737'),
('20180305111648'),
('20180315132521'),
('20180315145436'),
('20180315150348'),
('20180315185255'),
('20180325001828'),
('20180327020701'),
('20180329145257'),
('20180329145557'),
('20180329154130'),
('20180403115050'),
('20180403134930'),
('20180403135744'),
('20180403145234'),
('20180403231931'),
('20180406080444'),
('20180406185130'),
('20180407082641'),
('20180409115144'),
('20180409115902'),
('20180416160438'),
('20180417085823'),
('20180417111305'),
('20180417175453'),
('20180419122223'),
('20180425094920'),
('20180425152420'),
('20180425224307'),
('20180501082703'),
('20180501141718'),
('20180516094307'),
('20180516101606'),
('20180516104042'),
('20180516105035'),
('20180516110336'),
('20180516124235'),
('20180516131005'),
('20180516133138'),
('20180517084245'),
('20180517101842'),
('20180517110003'),
('20180522105709'),
('20180522121046'),
('20180522165830'),
('20180524170927'),
('20180525101406'),
('20180529125011'),
('20180530122201'),
('20180605104154'),
('20180613140856'),
('20180613144712'),
('20180704103131'),
('20180704115110'),
('20180708014826'),
('20180708171446'),
('20180716115113'),
('20180718113111'),
('20180719123616'),
('20180719172203'),
('20180720165705'),
('20180726110440'),
('20180727054453'),
('20180803144827'),
('20180808144704'),
('20180813105100'),
('20180905112301'),
('20180925123806'),
('20181004114428'),
('20181017114624'),
('20181027192001'),
('20181028000150'),
('20181105102116'),
('20181105102422'),
('20181105102537'),
('20181105120211'),
('20181120113445'),
('20181126101312'),
('20181210162905'),
('20181219115439'),
('20181219133822'),
('20181226170925'),
('20181229051129'),
('20190110164859'),
('20190115165813'),
('20190116140939'),
('20190204142656'),
('20190213104708'),
('20190225171726'),
('20190401121727'),
('20190402130148'),
('20190426145506'),
('20190502103256'),
('20190529142209'),
('20190617090551'),
('20190624102330'),
('20190711114027'),
('20190723202251'),
('20190725131843'),
('20190726161540'),
('20190807092706'),
('20190813121822'),
('20190814102636'),
('20190816125948'),
('20190829035814'),
('20190829152927'),
('20190830082950'),
('20190902134819'),
('20190902141139'),
('20190904143050'),
('20190905050444'),
('20190910105717'),
('20190923085927'),
('20200117160600'),
('20200211124707'),
('20200220133250'),
('20200305140516'),
('20200316132213'),
('20200317080916'),
('20200414155144'),
('20200420141636'),
('20200504183201'),
('20200527130534'),
('20200603164002'),
('20200622185615'),
('20200728143753'),
('20200804091304'),
('20200805102000'),
('20200805102001'),
('20200805102002'),
('20200805144308'),
('20200806143442'),
('20200824172823'),
('20200826091118'),
('20200902082403'),
('20200903113109'),
('20200907133518'),
('20200908105929'),
('20200909083000'),
('20201001094156'),
('20201118151056'),
('20201204134602'),
('20201206205429'),
('20201207134745'),
('20201222155655'),
('20210112063704'),
('20210120135842'),
('20210128083207'),
('20210210133912'),
('20210219144535'),
('20210225123519'),
('20210302120855'),
('20210311145918'),
('20210317141836'),
('20210414105529'),
('20210416125059'),
('20210417120111'),
('20210426083359'),
('20210502125244'),
('20210512120717'),
('20210526072124'),
('20210604053235'),
('20210714075758'),
('20210721093857'),
('20210722125206'),
('20210727101029'),
('20210803084921'),
('20210806112457'),
('20210806112458'),
('20210806131828'),
('20210806144136'),
('20210806151717'),
('20210806185439'),
('20210807083117'),
('20210807083309'),
('20210807084947'),
('20210809090917'),
('20210810202928'),
('20210811181035'),
('20210812044904'),
('20210812065148'),
('20210812130229'),
('20210813085546'),
('20210813093012'),
('20210813125626'),
('20210813150209'),
('20210816044928'),
('20210817050515'),
('20210817100325'),
('20210818074322'),
('20210820101018'),
('20210821180954'),
('20210822080438'),
('20210823045327'),
('20210823052207'),
('20210823053134'),
('20210823065105'),
('20210823183710'),
('20210824045320'),
('20210824105826'),
('20210824110350'),
('20210824162834'),
('20210824183549'),
('20210824190605'),
('20210824190750'),
('20210825114229'),
('20210825114751'),
('20210826123059'),
('20210827090805'),
('20210827173257'),
('20210829111838'),
('20210831043113'),
('20210831045259'),
('20210831072354'),
('20210908142557'),
('20210908143407'),
('20210910085149'),
('20210910085819'),
('20210915190259'),
('20210916181035'),
('20210924153647'),
('20210928060422'),
('20210929165211'),
('20211003172753'),
('20211018193526'),
('20211019114204'),
('20211019140943'),
('20211020085635'),
('20211025132500'),
('20211026141101'),
('20211112205804'),
('20211116054502'),
('20211122110601'),
('20211203102904');


