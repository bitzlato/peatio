# frozen_string_literal: true

FactoryBot.define do
  factory :market do
    engine { create(:engine) }
    trait :btc_usd do
      symbol            { 'btc_usd' }
      type              { 'spot' }
      base_currency     { 'btc' }
      quote_currency    { 'usd' }
      amount_precision  { 8 }
      price_precision   { 2 }
      min_price         { 0.01 }
      min_amount        { 0.00000001 }
      position          { 1 }
      state             { :enabled }
    end

    trait :btc_eth do
      symbol            { 'btc_eth' }
      type              { 'spot' }
      base_currency     { 'btc' }
      quote_currency    { 'eth' }
      amount_precision  { 4 }
      price_precision   { 6 }
      min_price         { 0.000001 }
      min_amount        { 0.0001 }
      position          { 2 }
      state             { :enabled }
    end

    trait :btc_eur do
      symbol            { 'btc_eur' }
      type              { 'spot' }
      base_currency     { 'btc' }
      quote_currency    { 'eur' }
      amount_precision  { 8 }
      price_precision   { 2 }
      min_price         { 0.01 }
      min_amount        { 0.00000001 }
      position          { 3 }
      state             { :enabled }
    end

    trait :eth_usd do
      symbol            { 'eth_usd' }
      type              { 'spot' }
      base_currency     { 'eth' }
      quote_currency    { 'usd' }
      amount_precision  { 6 }
      price_precision   { 4 }
      min_price         { 0.01 }
      min_amount        { 0.0001 }
      position          { 4 }
      state             { :enabled }
    end

    trait :btc_trst do
      symbol            { 'btc_trst' }
      type              { 'spot' }
      base_currency     { 'btc' }
      quote_currency    { 'trst' }
      amount_precision  { 6 }
      price_precision   { 4 }
      min_price         { 0.01 }
      min_amount        { 0.0001 }
      position          { 5 }
      state             { :enabled }
    end

    trait :xagm_cxusd do
      symbol            { 'xagm.cxusd' }
      type              { 'spot' }
      base_currency     { 'xagm.cx' }
      quote_currency    { 'usd' }
      amount_precision  { 6 }
      price_precision   { 4 }
      min_price         { 0.01 }
      min_amount        { 0.0001 }
      position          { 4 }
      state             { :enabled }
    end

    trait :btc_eth_qe do
      symbol            { 'btc_eth' }
      type              { 'qe' }
      base_currency     { 'btc' }
      quote_currency    { 'eth' }
      amount_precision  { 4 }
      price_precision   { 6 }
      min_price         { 0.000001 }
      min_amount        { 0.0001 }
      position          { 2 }
      state             { :enabled }
    end
  end
end
