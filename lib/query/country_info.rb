# frozen_string_literal: true

require_relative '../sparql'

CountryStruct = SelfAwareStruct.new(:me, :populations, :executive, :heads, :offices, :legislatures)

module Query
  class CountryInfo
    def initialize(id:)
      @id = id
    end

    def data
      h = results.first
      CountryStruct.new(
        h[:country],
        results.map { |row| row[:population] }.uniq.compact,
        h[:executive],
        results.map { |row| row[:head] }.uniq.compact,
        results.map { |row| row[:office] }.uniq.compact,
        results.map { |row| row[:legislature] }.uniq.compact
      )
    end

    private

    attr_reader :id

    def sparql
      @sparql ||= <<~SPARQL
        SELECT ?country ?countryLabel ?population ?executive ?executiveLabel ?legislature ?legislatureLabel ?head ?headLabel ?office ?officeLabel WHERE
        {
          BIND(wd:#{id} AS ?country)
          OPTIONAL { ?country wdt:P1082 ?population }.
          OPTIONAL {
            ?country wdt:P194 ?legislature
            MINUS { ?legislature wdt:P576 ?legislatureEnd }
          }.
          OPTIONAL { ?country wdt:P208 ?executive }.
          OPTIONAL { ?country wdt:P6 ?head }.
          OPTIONAL { ?country wdt:P1313 ?office }.
          SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
        }
      SPARQL
    end

    def results
      @results ||= Sparql.new(sparql).results
    end
  end
end
