# frozen_string_literal: true

require_relative '../sparql'

LegislatureStruct = SelfAwareStruct.new(:me, :type, :jurisdiction, :country, :seats, :chambers)

module Page
  class Legislature
    def initialize(id:)
      @id = id
    end

    def title
      "Legislative Explorer: #{legislature.name}"
    end

    def country
      legislature.country
    end

    def legislature
      row = Sparql.new(sparql).results.first
      LegislatureStruct.new(*row.values_at(:legislature, :type, :jurisdiction, :country, :seats), chambers)
    end

    def type
      @type ||= Sparql.new(type_sparql).results.map { |row| row[:isa].name }.find { |name| name.include? 'cameral legislature' }
    end

    def chambers
      @chambers ||= Sparql.new(parts_sparql).results.map { |row| row[:part] }
    end

    def unicameral?
      types.include? 'unicameral legislature'
    end

    def bicameral?
      types.include? 'bicameral legislature'
    end

    def chamber?
      types.include?('lower house') || types.include?('upper house')
    end

    private

    def types
      @types ||= Sparql.new(type_sparql).results.map { |row| row[:isa].name }.to_set
    end

    def type_sparql
      @type_sparql ||= <<~SPARQL
        SELECT ?isa ?isaLabel WHERE
        {
          wd:#{@id} wdt:P31 ?isa .
          SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
        }
      SPARQL
    end

    def parts_sparql
      @parts_sparql ||= <<~SPARQL
        SELECT DISTINCT ?part ?partLabel WHERE
        {
          wd:#{@id} wdt:P527 ?part .
          ?part wdt:P31/wdt:P279* wd:Q10553309 .
          SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
        }
      SPARQL
    end

    def sparql
      @sparql ||= <<~SPARQL
        SELECT ?legislature ?legislatureLabel ?jurisdiction ?jurisdictionLabel ?country ?countryLabel ?seats ?part ?partLabel WHERE
        {
          BIND(wd:#{@id} AS ?legislature)
          OPTIONAL { ?legislature wdt:P1342 ?seats }.
          OPTIONAL { ?legislature wdt:P1001 ?jurisdiction }.
          OPTIONAL { ?legislature wdt:P17 ?country }.
          SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
        }
      SPARQL
    end
  end
end
