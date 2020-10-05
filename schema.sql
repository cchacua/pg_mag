--------------------------------------------------------
--------------------------------------------------------
-- MICROSOFT ACADEMIC GRAPH - POSTGRESQL SCRIPT

-- Author: Christian Chacua
-- Last upate: October 5, 2020

-- Requires the Postgis Extension to enable the Spatial and Geographic objects 
-- Requires the pg_trgm Extension to enable the gin_trgm_ops class
--------------------------------------------------------
--------------------------------------------------------

\timing 

CREATE EXTENSION postgis;
CREATE EXTENSION pg_trgm;

-- Create schema or tablespace for postgis functions
DROP SCHEMA mag202009 CASCADE;
CREATE SCHEMA mag202009;

--------------------------------------------------------
--------------------------------------------------------
-- MAG Core
--------------------------------------------------------
--------------------------------------------------------

--------------------------------------------------------
-- affiliations
--------------------------------------------------------

DROP TABLE IF EXISTS mag202009.affiliations;
CREATE TABLE mag202009.affiliations(
    AffiliationId BIGINT PRIMARY KEY,
    Rank INT,
    NormalizedName VARCHAR(150),
    DisplayName VARCHAR(150),
    GridId VARCHAR(15),
    OfficialPage TEXT,
    WikiPage TEXT,
    PaperCount BIGINT,
    PaperFamilyCount BIGINT,
    CitationCount BIGINT,
    Iso3166Code VARCHAR(3),
    Latitude FLOAT8,
    Longitude FLOAT8,
    CreatedDate DATE,
    geom geometry(POINT,4326)
  );

COPY mag202009.affiliations(AffiliationId, Rank, NormalizedName, DisplayName, GridId, OfficialPage, WikiPage, PaperCount, PaperFamilyCount, CitationCount, Iso3166Code, Latitude, Longitude, CreatedDate) FROM '/home/input/mag/Affiliations.txt' null as '';

CREATE INDEX idx_affiliations_NormalizedName ON mag202009.affiliations(NormalizedName);
CREATE INDEX idx_affiliations_GridId ON mag202009.affiliations(GridId);
CREATE INDEX gidx_affiliations_NormalizedName ON mag202009.affiliations USING GIN(NormalizedName gin_trgm_ops);

UPDATE mag202009.affiliations
SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude),4326);
CREATE INDEX idx_affiliations_geom ON mag202009.affiliations USING gist(geom);

--------------------------------------------------------
-- AuthorExtendedAttributes
--------------------------------------------------------

DROP TABLE IF EXISTS mag202009.authorextendedattributes;
CREATE TABLE mag202009.authorextendedattributes(
    id SERIAL PRIMARY KEY,
    AuthorId BIGINT,
    AttributeType SMALLINT,
    AttributeValue VARCHAR(100)
  );

COPY mag202009.authorextendedattributes(AuthorId, AttributeType, AttributeValue) FROM '/home/input/mag/AuthorExtendedAttributes.txt' null as '';

CREATE INDEX idx_authorextendedattributes_AuthorId ON mag202009.authorextendedattributes(AuthorId);
CREATE INDEX idx_authorextendedattributes_AttributeValue ON mag202009.authorextendedattributes(AttributeValue);

--------------------------------------------------------
-- Authors
--------------------------------------------------------
DROP TABLE IF EXISTS mag202009.Authors;
CREATE TABLE mag202009.Authors(
    AuthorId BIGINT PRIMARY KEY,
    Rank INT,
    NormalizedName VARCHAR(200),
    DisplayName VARCHAR(400),
    LastKnownAffiliationId BIGINT,
    PaperCount BIGINT,
    PaperFamilyCount BIGINT,
    CitationCount BIGINT,
    CreatedDate DATE
  );

COPY mag202009.Authors(AuthorId, Rank, NormalizedName, DisplayName, LastKnownAffiliationId, PaperCount, PaperFamilyCount, CitationCount, CreatedDate) FROM '/home/input/mag/Authors.txt' null as '';

CREATE INDEX idx_Authors_NormalizedName ON mag202009.Authors(NormalizedName);
CREATE INDEX idx_Authors_LastKnownAffiliationId ON mag202009.Authors(LastKnownAffiliationId);
-- CREATE INDEX gidx_Authors_NormalizedName ON mag202009.Authors USING GIN(NormalizedName gin_trgm_ops);

--------------------------------------------------------
-- ConferenceInstances
--------------------------------------------------------
DROP TABLE IF EXISTS mag202009.ConferenceInstances;
CREATE TABLE mag202009.ConferenceInstances(
    ConferenceInstanceId BIGINT PRIMARY KEY,
    NormalizedName VARCHAR(50),
    DisplayName VARCHAR(50),
    ConferenceSeriesId BIGINT,
    Location VARCHAR(255),
    OfficialUrl TEXT,
    StartDate DATE,
    EndDate DATE,
    AbstractRegistrationDate DATE,
    SubmissionDeadlineDate DATE,
    NotificationDueDate DATE,
    FinalVersionDueDate DATE,
    PaperCount BIGINT,
    PaperFamilyCount BIGINT,
    CitationCount BIGINT,
    Latitude FLOAT8,
    Longitude FLOAT8,
    CreatedDate DATE,
    geom geometry(POINT,4326)
  );

COPY mag202009.ConferenceInstances(ConferenceInstanceId, NormalizedName, DisplayName, ConferenceSeriesId, Location, OfficialUrl, StartDate, EndDate, AbstractRegistrationDate, SubmissionDeadlineDate, NotificationDueDate, FinalVersionDueDate, PaperCount, PaperFamilyCount, CitationCount, Latitude, Longitude, CreatedDate) FROM '/home/input/mag/ConferenceInstances.txt' null as '';

CREATE INDEX idx_ConferenceInstances_NormalizedName ON mag202009.ConferenceInstances(NormalizedName);
CREATE INDEX idx_ConferenceInstances_ConferenceSeriesId ON mag202009.ConferenceInstances(ConferenceSeriesId);
CREATE INDEX idx_ConferenceInstances_Location ON mag202009.ConferenceInstances(Location);

UPDATE mag202009.ConferenceInstances
SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude),4326);
CREATE INDEX idx_ConferenceInstances_geom ON mag202009.ConferenceInstances USING gist(geom);

--------------------------------------------------------
-- ConferenceSeries
--------------------------------------------------------
DROP TABLE IF EXISTS mag202009.ConferenceSeries;
CREATE TABLE mag202009.ConferenceSeries(
    ConferenceSeriesId BIGINT PRIMARY KEY,
    Rank INT,
    NormalizedName VARCHAR(50),
    DisplayName VARCHAR(200),
    PaperCount BIGINT,
    PaperFamilyCount BIGINT,
    CitationCount BIGINT,
    CreatedDate DATE
  );

COPY mag202009.ConferenceSeries(ConferenceSeriesId, Rank, NormalizedName, DisplayName, PaperCount, PaperFamilyCount, CitationCount, CreatedDate) FROM '/home/input/mag/ConferenceSeries.txt' null as '';

CREATE INDEX idx_ConferenceSeries_NormalizedName ON mag202009.ConferenceSeries(NormalizedName);

--------------------------------------------------------
-- Journals
--------------------------------------------------------
DROP TABLE IF EXISTS mag202009.Journals;
CREATE TABLE mag202009.Journals(
    JournalId BIGINT  PRIMARY KEY,
    Rank INT,
    NormalizedName VARCHAR(255),
    DisplayName VARCHAR(255),
    Issn VARCHAR(15),
    Publisher VARCHAR(100),
    Webpage TEXT,
    PaperCount BIGINT,
    PaperFamilyCount BIGINT,
    CitationCount BIGINT,
    CreatedDate DATE
  );

COPY mag202009.Journals(JournalId, Rank, NormalizedName, DisplayName, Issn, Publisher, Webpage, PaperCount, PaperFamilyCount, CitationCount, CreatedDate) FROM '/home/input/mag/Journals.txt' null as '';

CREATE INDEX idx_Journals_NormalizedName ON mag202009.Journals(NormalizedName);
CREATE INDEX idx_Journals_Issn ON mag202009.Journals(Issn);

--------------------------------------------------------
-- PaperAuthorAffiliations
--------------------------------------------------------
DROP TABLE IF EXISTS mag202009.PaperAuthorAffiliations;
CREATE TABLE mag202009.PaperAuthorAffiliations(
    id BIGSERIAL PRIMARY KEY,
    PaperId BIGINT,
    AuthorId BIGINT,
    AffiliationId BIGINT,
    AuthorSequenceNumber SMALLINT,
    OriginalAuthor TEXT,
    OriginalAffiliation TEXT
  );

/*
-- The input files may required some modifications 
\! sed -e 's/\\/\\\\/g' < PaperAuthorAffiliations.txt > PaperAuthorAffiliations_.txt
\! tr -d '\000' < PaperAuthorAffiliations_.txt > PaperAuthorAffiliations__.txt
*/

COPY mag202009.PaperAuthorAffiliations(PaperId, AuthorId, AffiliationId, AuthorSequenceNumber, OriginalAuthor, OriginalAffiliation)  FROM '/home/input/mag/PaperAuthorAffiliations__.txt' NULL as ''; 

CREATE INDEX idx_PaperAuthorAffiliations_PaperId ON mag202009.PaperAuthorAffiliations(PaperId);
CREATE INDEX idx_PaperAuthorAffiliations_AuthorId ON mag202009.PaperAuthorAffiliations(AuthorId);
CREATE INDEX idx_PaperAuthorAffiliations_AffiliationId ON mag202009.PaperAuthorAffiliations(AffiliationId);

--------------------------------------------------------
-- PaperReferences
--------------------------------------------------------
DROP TABLE IF EXISTS mag202009.PaperReferences;
CREATE TABLE mag202009.PaperReferences(
    id SERIAL PRIMARY KEY,
    PaperId BIGINT,
    PaperReferenceId BIGINT
  );

COPY mag202009.PaperReferences(PaperId, PaperReferenceId) FROM '/home/input/mag/PaperReferences.txt' null as '';

CREATE INDEX idx_PaperReferences_PaperId ON mag202009.PaperReferences(PaperId);
CREATE INDEX idx_PaperReferences_PaperReferenceId ON mag202009.PaperReferences(PaperReferenceId);

--------------------------------------------------------
-- PaperResources
--------------------------------------------------------
DROP TABLE IF EXISTS mag202009.PaperResources;
CREATE TABLE mag202009.PaperResources(
    id SERIAL PRIMARY KEY,
    PaperId BIGINT,
    ResourceType SMALLINT,
    ResourceUrl TEXT,
    SourceUrl TEXT,
    RelationshipType SMALLINT
  );

COPY mag202009.PaperResources(PaperId, ResourceType, ResourceUrl, SourceUrl, RelationshipType) FROM '/home/input/mag/PaperResources.txt' null as '';

CREATE INDEX idx_PaperResources_PaperId ON mag202009.PaperResources(PaperId);

--------------------------------------------------------
-- Papers
--------------------------------------------------------
DROP TABLE IF EXISTS mag202009.Papers;
CREATE TABLE mag202009.Papers(
    PaperId BIGINT PRIMARY KEY,
    Rank INT,
    Doi VARCHAR(255),
    DocType VARCHAR(20),
    PaperTitle TEXT,
    PaperTitle_idx TSVECTOR,
    OriginalTitle TEXT,
    BookTitle TEXT,
    Year SMALLINT,
    Date DATE,
    OnlineDate DATE,
    Publisher TEXT,
    JournalId BIGINT,
    ConferenceSeriesId BIGINT,
    ConferenceInstanceId BIGINT,
    Volume VARCHAR(100),
    Issue VARCHAR(100),
    FirstPage VARCHAR(100),
    LastPage TEXT,
    ReferenceCount BIGINT,
    CitationCount BIGINT,
    EstimatedCitation BIGINT,
    OriginalVenue TEXT,
    FamilyId BIGINT,
    FamilyRank INT,
    CreatedDate DATE
  );

/*
\! sed -e 's/\\/\\\\/g' < Papers.txt > Papers_.txt
\! tr -d '\000' < Papers_.txt > Papers__.txt
*/

COPY mag202009.Papers(PaperId, Rank, Doi, DocType, PaperTitle, OriginalTitle, BookTitle, Year, Date, OnlineDate, Publisher, JournalId, ConferenceSeriesId, ConferenceInstanceId, Volume, Issue, FirstPage, LastPage, ReferenceCount, CitationCount, EstimatedCitation, OriginalVenue, FamilyId, FamilyRank, CreatedDate) FROM '/home/input/mag/Papers__.txt' NULL as ''; 

CREATE INDEX idx_Papers_PaperTitle ON mag202009.Papers(PaperTitle);
CREATE INDEX idx_Papers_OriginalTitle ON mag202009.Papers(OriginalTitle);
CREATE INDEX idx_Papers_BookTitle ON mag202009.Papers(BookTitle);
CREATE INDEX idx_Papers_Year ON mag202009.Papers(Year);
CREATE INDEX idx_Papers_JournalId ON mag202009.Papers(JournalId);
CREATE INDEX idx_Papers_FamilyId ON mag202009.Papers(FamilyId);
CREATE INDEX gidx_Papers_PaperTitle ON  mag202009.Papers USING GIN(PaperTitle gin_trgm_ops);
CREATE INDEX gidx_Papers_BookTitle ON  mag202009.Papers USING GIN(BookTitle gin_trgm_ops);

--------------------------------------------------------
-- PaperExtendedAttributes
--------------------------------------------------------
DROP TABLE IF EXISTS mag202009.PaperExtendedAttributes;
CREATE TABLE mag202009.PaperExtendedAttributes(
    id SERIAL PRIMARY KEY,
    PaperId BIGINT,
    AttributeType SMALLINT,
    AttributeValue TEXT
  );
COPY mag202009.PaperExtendedAttributes(PaperId, AttributeType, AttributeValue) FROM '/home/input/mag/PaperExtendedAttributes.txt' WITH CSV delimiter E'\t'  ESCAPE '\' QUOTE E'\b'  null as ''; 
-- '

CREATE INDEX idx_PaperExtendedAttributes_PaperId ON mag202009.PaperExtendedAttributes(PaperId);

--------------------------------------------------------
-- PaperUrls
--------------------------------------------------------
DROP TABLE IF EXISTS mag202009.PaperUrls;
CREATE TABLE mag202009.PaperUrls(
    id SERIAL PRIMARY KEY,
    PaperId BIGINT,
    SourceType SMALLINT,
    SourceUrl TEXT,
    LanguageCode VARCHAR(10)
  );

COPY mag202009.PaperUrls(PaperId, SourceType, SourceUrl, LanguageCode) FROM '/home/input/mag/PaperUrls.txt' WITH CSV delimiter E'\t'   QUOTE E'\b'  null as ''; 

CREATE INDEX idx_PaperUrls_PaperId ON mag202009.PaperUrls(PaperId);

--------------------------------------------------------
--------------------------------------------------------
-- MAG NLP
--------------------------------------------------------
--------------------------------------------------------

--------------------------------------------------------
-- PaperAbstractsInvertedIndex
--------------------------------------------------------

DROP TABLE IF EXISTS mag202009.PaperAbstractsInvertedIndex;
CREATE TABLE mag202009.PaperAbstractsInvertedIndex(
    PaperId BIGINT PRIMARY KEY,
    IndexedAbstract JSONB
  );

COPY mag202009.PaperAbstractsInvertedIndex(PaperId, IndexedAbstract) FROM '/home/input/nlp/PaperAbstractsInvertedIndex.txt.1' null as '';
COPY mag202009.PaperAbstractsInvertedIndex(PaperId, IndexedAbstract) FROM '/home/input/nlp/PaperAbstractsInvertedIndex.txt.2' null as '';

--------------------------------------------------------
-- PaperCitationContexts
--------------------------------------------------------
DROP TABLE IF EXISTS mag202009.PaperCitationContexts;
CREATE TABLE mag202009.PaperCitationContexts(
    id SERIAL PRIMARY KEY,
    PaperId BIGINT,
    PaperReferenceId BIGINT,
    CitationContext TEXT
  );

COPY mag202009.PaperCitationContexts(PaperId, PaperReferenceId, CitationContext) FROM '/home/input/nlp/PaperCitationContexts.txt' null as '';

CREATE INDEX idx_PaperCitationContexts_PaperId ON mag202009.PaperCitationContexts(PaperId);

--------------------------------------------------------
--------------------------------------------------------
-- MAG ADVANCED
--------------------------------------------------------
--------------------------------------------------------

--------------------------------------------------------
-- EntityRelatedEntities
--------------------------------------------------------
DROP TABLE IF EXISTS mag202009.EntityRelatedEntities;
CREATE TABLE mag202009.EntityRelatedEntities(
    id SERIAL PRIMARY KEY,
    EntityId BIGINT,
    EntityType VARCHAR(2),
    RelatedEntityId BIGINT,
    RelatedEntityType VARCHAR(2),
    RelatedType SMALLINT,
    Score FLOAT8
  );

COPY mag202009.EntityRelatedEntities(EntityId, EntityType, RelatedEntityId, RelatedEntityType, RelatedType, Score) FROM '/home/input/advanced/EntityRelatedEntities.txt' null as '';

CREATE INDEX idx_EntityRelatedEntities_EntityId ON mag202009.EntityRelatedEntities(EntityId);
CREATE INDEX idx_EntityRelatedEntities_RelatedEntityId ON mag202009.EntityRelatedEntities(RelatedEntityId);

--------------------------------------------------------
-- PaperRecommendations
--------------------------------------------------------
DROP TABLE IF EXISTS mag202009.PaperRecommendations;
CREATE TABLE mag202009.PaperRecommendations(
    id BIGSERIAL PRIMARY KEY,
    PaperId BIGINT,
    RecommendedPaperId BIGINT,
    Score FLOAT8
  );

COPY mag202009.PaperRecommendations(PaperId, RecommendedPaperId, Score) FROM '/home/input/advanced/PaperRecommendations.txt' null as '';

CREATE INDEX idx_PaperRecommendations_PaperId ON mag202009.PaperRecommendations(PaperId);
CREATE INDEX idx_PaperRecommendations_RecommendedPaperId ON mag202009.PaperRecommendations(RecommendedPaperId);

--------------------------------------------------------
-- PaperFieldsOfStudy
--------------------------------------------------------
DROP TABLE IF EXISTS mag202009.PaperFieldsOfStudy;
CREATE TABLE mag202009.PaperFieldsOfStudy(
    id SERIAL PRIMARY KEY,
    PaperId BIGINT,
    FieldOfStudyId BIGINT,
    Score FLOAT8
  );

COPY mag202009.PaperFieldsOfStudy(PaperId, FieldOfStudyId, Score) FROM '/home/input/advanced/PaperFieldsOfStudy.txt' null as '';

CREATE INDEX idx_PaperFieldsOfStudy_PaperId ON mag202009.PaperFieldsOfStudy(PaperId);
CREATE INDEX idx_PaperFieldsOfStudy_FieldOfStudyId ON mag202009.PaperFieldsOfStudy(FieldOfStudyId);

--------------------------------------------------------
-- FieldOfStudyChildren
--------------------------------------------------------
DROP TABLE IF EXISTS mag202009.FieldOfStudyChildren;
CREATE TABLE mag202009.FieldOfStudyChildren(
    id SERIAL PRIMARY KEY,
    FieldOfStudyId BIGINT,
    ChildFieldOfStudyId BIGINT
  );

COPY mag202009.FieldOfStudyChildren(FieldOfStudyId, ChildFieldOfStudyId) FROM '/home/input/advanced/FieldOfStudyChildren.txt' null as '';

CREATE INDEX idx_FieldOfStudyChildren_FieldOfStudyId ON mag202009.FieldOfStudyChildren(FieldOfStudyId);
CREATE INDEX idx_FieldOfStudyChildren_ChildFieldOfStudyId ON mag202009.FieldOfStudyChildren(ChildFieldOfStudyId);

--------------------------------------------------------
-- FieldOfStudyExtendedAttributes
--------------------------------------------------------
DROP TABLE IF EXISTS mag202009.FieldOfStudyExtendedAttributes;
CREATE TABLE mag202009.FieldOfStudyExtendedAttributes(
    id SERIAL PRIMARY KEY,
    FieldOfStudyId BIGINT,
    AttributeType SMALLINT,
    AttributeValue TEXT
  );

COPY mag202009.FieldOfStudyExtendedAttributes(FieldOfStudyId, AttributeType, AttributeValue) FROM '/home/input/advanced/FieldOfStudyExtendedAttributes.txt' null as '';

CREATE INDEX idx_FieldOfStudyExtendedAttributes_FieldOfStudyId ON mag202009.FieldOfStudyExtendedAttributes(FieldOfStudyId);

--------------------------------------------------------
-- FieldsOfStudy
--------------------------------------------------------
DROP TABLE IF EXISTS mag202009.FieldsOfStudy;
CREATE TABLE mag202009.FieldsOfStudy(
    FieldOfStudyId BIGINT PRIMARY KEY,
    Rank INT,
    NormalizedName VARCHAR(255),
    DisplayName VARCHAR(255),
    MainType VARCHAR(255),
    Level SMALLINT,
    PaperCount BIGINT,
    PaperFamilyCount BIGINT,
    CitationCount BIGINT,
    CreatedDate DATE
  );

COPY mag202009.FieldsOfStudy(FieldOfStudyId, Rank, NormalizedName, DisplayName, MainType, Level, PaperCount, PaperFamilyCount, CitationCount, CreatedDate) FROM '/home/input/advanced/FieldsOfStudy.txt' null as '';

--------------------------------------------------------
-- RelatedFieldOfStudy
--------------------------------------------------------
DROP TABLE IF EXISTS mag202009.RelatedFieldOfStudy;
CREATE TABLE mag202009.RelatedFieldOfStudy(
    id SERIAL PRIMARY KEY,
    FieldOfStudyId1 BIGINT,
    Type1 VARCHAR(255),
    FieldOfStudyId2 BIGINT,
    Type2 VARCHAR(255),
    Rank FLOAT8
  );

COPY mag202009.RelatedFieldOfStudy(FieldOfStudyId1, Type1, FieldOfStudyId2, Type2, Rank) FROM '/home/input/advanced/RelatedFieldOfStudy.txt' null as '';

CREATE INDEX idx_RelatedFieldOfStudy_FieldOfStudyId1 ON mag202009.RelatedFieldOfStudy(FieldOfStudyId1);
CREATE INDEX idx_RelatedFieldOfStudy_FieldOfStudyId2 ON mag202009.RelatedFieldOfStudy(FieldOfStudyId2);
