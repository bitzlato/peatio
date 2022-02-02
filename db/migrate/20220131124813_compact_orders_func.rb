# frozen_string_literal: true

class CompactOrdersFunc < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
    CREATE OR REPLACE FUNCTION compact_orders(
        min_date DATE,
        max_date DATE,
        OUT pointer INTEGER,
        OUT counter INTEGER
    )
    LANGUAGE plpgsql
    AS $$
    BEGIN
        -- Temporary liabilities table
        CREATE TEMPORARY TABLE IF NOT EXISTS liabilities_tmp(LIKE liabilities INCLUDING ALL);

        -- Copy liabilities to tmp
        INSERT INTO liabilities_tmp SELECT * FROM liabilities
        WHERE LOWER(reference_type) = LOWER('Order') AND created_at BETWEEN min_date AND max_date;

        -- Set counter and pointer vars
        get diagnostics counter = row_count;
        SELECT to_char(max_date, 'YYYYMMDD')::integer INTO pointer;

        -- Delete liabilities to compact
        DELETE FROM liabilities WHERE LOWER(reference_type) = LOWER('Order') AND created_at BETWEEN min_date AND max_date;

        INSERT INTO liabilities
        SELECT MAX(id), code, currency_id, member_id, 'CompactOrders',
        to_char(max_date, 'YYYYMMDD')::integer, SUM(debit)::decimal, SUM(credit)::decimal, DATE(created_at), NOW()::date FROM liabilities_tmp
        WHERE LOWER(reference_type) = LOWER('Order') AND created_at BETWEEN min_date AND max_date
        GROUP BY code, currency_id, member_id, DATE(created_at);

        DROP TABLE liabilities_tmp;
    END
    $$;
    SQL
  end

  def down
    execute <<-SQL
    CREATE OR REPLACE FUNCTION compact_orders(
        min_date DATE,
        max_date DATE,
        OUT pointer INTEGER,
        OUT counter INTEGER
    )
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
    SQL
  end
end
