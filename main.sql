--------------------------------------------------------
--------------------------------------------------------
-- MICROSOFT ACADEMIC GRAPH - POSTGRESQL SCRIPT

-- Author: Christian Chacua
-- Last upate: October 14, 2020

-- Requires the postgis Extension to enable the Spatial and Geographic objects 
-- Requires the pg_trgm Extension to enable the gin_trgm_ops class

-- CREATE EXTENSION postgis;
-- CREATE EXTENSION pg_trgm;
--------------------------------------------------------
--------------------------------------------------------

\timing 


-- Create schema or tablespace for postgis functions
DROP SCHEMA mag CASCADE;
CREATE SCHEMA mag;

--------------------------------------------------------
--------------------------------------------------------
-- MAG Core
--------------------------------------------------------
--------------------------------------------------------

--------------------------------------------------------
-- affiliations
--------------------------------------------------------

DROP TABLE IF EXISTS mag.affiliations;
CREATE TABLE mag.affiliations(
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

COPY mag.affiliations(AffiliationId, Rank, NormalizedName, DisplayName, GridId, OfficialPage, WikiPage, PaperCount, PaperFamilyCount, CitationCount, Iso3166Code, Latitude, Longitude, CreatedDate) FROM '/home/input/mag/Affiliations.txt' null as '';

CREATE INDEX idx_affiliations_NormalizedName ON mag.affiliations(NormalizedName);
CREATE INDEX idx_affiliations_GridId ON mag.affiliations(GridId);
CREATE INDEX gidx_affiliations_NormalizedName ON mag.affiliations USING GIN(NormalizedName gin_trgm_ops);

UPDATE mag.affiliations
SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude),4326);
CREATE INDEX idx_affiliations_geom ON mag.affiliations USING gist(geom);

--------------------------------------------------------
-- AuthorExtendedAttributes
--------------------------------------------------------

DROP TABLE IF EXISTS mag.authorextendedattributes;
CREATE TABLE mag.authorextendedattributes(
    id SERIAL PRIMARY KEY,
    AuthorId BIGINT,
    AttributeType SMALLINT,
    AttributeValue VARCHAR(100)
  );

COPY mag.authorextendedattributes(AuthorId, AttributeType, AttributeValue) FROM '/home/input/mag/AuthorExtendedAttributes.txt' null as '';

CREATE INDEX idx_authorextendedattributes_AuthorId ON mag.authorextendedattributes(AuthorId);
CREATE INDEX idx_authorextendedattributes_AttributeValue ON mag.authorextendedattributes(AttributeValue);

--------------------------------------------------------
-- Authors
--------------------------------------------------------
DROP TABLE IF EXISTS mag.Authors;
CREATE TABLE mag.Authors(
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

COPY mag.Authors(AuthorId, Rank, NormalizedName, DisplayName, LastKnownAffiliationId, PaperCount, PaperFamilyCount, CitationCount, CreatedDate) FROM '/home/input/mag/Authors.txt' null as '';

CREATE INDEX idx_Authors_NormalizedName ON mag.Authors(NormalizedName);
CREATE INDEX idx_Authors_LastKnownAffiliationId ON mag.Authors(LastKnownAffiliationId);
-- CREATE INDEX gidx_Authors_NormalizedName ON mag.Authors USING GIN(NormalizedName gin_trgm_ops);

--------------------------------------------------------
-- ConferenceInstances
--------------------------------------------------------
DROP TABLE IF EXISTS mag.ConferenceInstances;
CREATE TABLE mag.ConferenceInstances(
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

COPY mag.ConferenceInstances(ConferenceInstanceId, NormalizedName, DisplayName, ConferenceSeriesId, Location, OfficialUrl, StartDate, EndDate, AbstractRegistrationDate, SubmissionDeadlineDate, NotificationDueDate, FinalVersionDueDate, PaperCount, PaperFamilyCount, CitationCount, Latitude, Longitude, CreatedDate) FROM '/home/input/mag/ConferenceInstances.txt' null as '';

CREATE INDEX idx_ConferenceInstances_NormalizedName ON mag.ConferenceInstances(NormalizedName);
CREATE INDEX idx_ConferenceInstances_ConferenceSeriesId ON mag.ConferenceInstances(ConferenceSeriesId);
CREATE INDEX idx_ConferenceInstances_Location ON mag.ConferenceInstances(Location);

UPDATE mag.ConferenceInstances
SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude),4326);
CREATE INDEX idx_ConferenceInstances_geom ON mag.ConferenceInstances USING gist(geom);

--------------------------------------------------------
-- ConferenceSeries
--------------------------------------------------------
DROP TABLE IF EXISTS mag.ConferenceSeries;
CREATE TABLE mag.ConferenceSeries(
    ConferenceSeriesId BIGINT PRIMARY KEY,
    Rank INT,
    NormalizedName VARCHAR(50),
    DisplayName VARCHAR(200),
    PaperCount BIGINT,
    PaperFamilyCount BIGINT,
    CitationCount BIGINT,
    CreatedDate DATE
  );

COPY mag.ConferenceSeries(ConferenceSeriesId, Rank, NormalizedName, DisplayName, PaperCount, PaperFamilyCount, CitationCount, CreatedDate) FROM '/home/input/mag/ConferenceSeries.txt' null as '';

CREATE INDEX idx_ConferenceSeries_NormalizedName ON mag.ConferenceSeries(NormalizedName);

--------------------------------------------------------
-- Journals
--------------------------------------------------------
DROP TABLE IF EXISTS mag.Journals;
CREATE TABLE mag.Journals(
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

COPY mag.Journals(JournalId, Rank, NormalizedName, DisplayName, Issn, Publisher, Webpage, PaperCount, PaperFamilyCount, CitationCount, CreatedDate) FROM '/home/input/mag/Journals.txt' null as '';

CREATE INDEX idx_Journals_NormalizedName ON mag.Journals(NormalizedName);
CREATE INDEX idx_Journals_Issn ON mag.Journals(Issn);

--------------------------------------------------------
-- PaperAuthorAffiliations
--------------------------------------------------------
DROP TABLE IF EXISTS mag.PaperAuthorAffiliations;
CREATE TABLE mag.PaperAuthorAffiliations(
    id BIGSERIAL PRIMARY KEY,
    PaperId BIGINT,
    AuthorId BIGINT,
    AffiliationId BIGINT,
    AuthorSequenceNumber SMALLINT,
    OriginalAuthor TEXT,
    OriginalAffiliation TEXT
  );

-- The input files may required some modifications 
\! sed -e 's/\\/\\\\/g' < PaperAuthorAffiliations.txt > PaperAuthorAffiliations_.txt
\! tr -d '\000' < PaperAuthorAffiliations_.txt > PaperAuthorAffiliations__.txt


COPY mag.PaperAuthorAffiliations(PaperId, AuthorId, AffiliationId, AuthorSequenceNumber, OriginalAuthor, OriginalAffiliation)  FROM '/home/input/mag/PaperAuthorAffiliations__.txt' NULL as ''; 

CREATE INDEX idx_PaperAuthorAffiliations_PaperId ON mag.PaperAuthorAffiliations(PaperId);
CREATE INDEX idx_PaperAuthorAffiliations_AuthorId ON mag.PaperAuthorAffiliations(AuthorId);
CREATE INDEX idx_PaperAuthorAffiliations_AffiliationId ON mag.PaperAuthorAffiliations(AffiliationId);

--------------------------------------------------------
-- PaperReferences
--------------------------------------------------------
DROP TABLE IF EXISTS mag.PaperReferences;
CREATE TABLE mag.PaperReferences(
    id SERIAL PRIMARY KEY,
    PaperId BIGINT,
    PaperReferenceId BIGINT
  );

COPY mag.PaperReferences(PaperId, PaperReferenceId) FROM '/home/input/mag/PaperReferences.txt' null as '';

CREATE INDEX idx_PaperReferences_PaperId ON mag.PaperReferences(PaperId);
CREATE INDEX idx_PaperReferences_PaperReferenceId ON mag.PaperReferences(PaperReferenceId);

--------------------------------------------------------
-- PaperResources
--------------------------------------------------------
DROP TABLE IF EXISTS mag.PaperResources;
CREATE TABLE mag.PaperResources(
    id SERIAL PRIMARY KEY,
    PaperId BIGINT,
    ResourceType SMALLINT,
    ResourceUrl TEXT,
    SourceUrl TEXT,
    RelationshipType SMALLINT
  );

COPY mag.PaperResources(PaperId, ResourceType, ResourceUrl, SourceUrl, RelationshipType) FROM '/home/input/mag/PaperResources.txt' null as '';

CREATE INDEX idx_PaperResources_PaperId ON mag.PaperResources(PaperId);

--------------------------------------------------------
-- Papers
--------------------------------------------------------
DROP TABLE IF EXISTS mag.Papers;
CREATE TABLE mag.Papers(
    PaperId BIGINT PRIMARY KEY,
    Rank INT,
    Doi VARCHAR(255),
    DocType VARCHAR(20),
    PaperTitle TEXT,
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


\! sed -e 's/\\/\\\\/g' < Papers.txt > Papers_.txt
\! tr -d '\000' < Papers_.txt > Papers__.txt


COPY mag.Papers(PaperId, Rank, Doi, DocType, PaperTitle, OriginalTitle, BookTitle, Year, Date, OnlineDate, Publisher, JournalId, ConferenceSeriesId, ConferenceInstanceId, Volume, Issue, FirstPage, LastPage, ReferenceCount, CitationCount, EstimatedCitation, OriginalVenue, FamilyId, FamilyRank, CreatedDate) FROM '/home/input/mag/Papers__.txt' NULL as ''; 

CREATE INDEX idx_Papers_PaperTitle ON mag.Papers(PaperTitle);
CREATE INDEX idx_Papers_OriginalTitle ON mag.Papers(OriginalTitle);
CREATE INDEX idx_Papers_BookTitle ON mag.Papers(BookTitle);
CREATE INDEX idx_Papers_Year ON mag.Papers(Year);
CREATE INDEX idx_Papers_JournalId ON mag.Papers(JournalId);
CREATE INDEX idx_Papers_FamilyId ON mag.Papers(FamilyId);
CREATE INDEX gidx_Papers_PaperTitle ON  mag.Papers USING GIN(PaperTitle gin_trgm_ops);
CREATE INDEX gidx_Papers_BookTitle ON  mag.Papers USING GIN(BookTitle gin_trgm_ops);

--------------------------------------------------------
-- PaperExtendedAttributes
--------------------------------------------------------
DROP TABLE IF EXISTS mag.PaperExtendedAttributes;
CREATE TABLE mag.PaperExtendedAttributes(
    id SERIAL PRIMARY KEY,
    PaperId BIGINT,
    AttributeType SMALLINT,
    AttributeValue TEXT
  );
COPY mag.PaperExtendedAttributes(PaperId, AttributeType, AttributeValue) FROM '/home/input/mag/PaperExtendedAttributes.txt' WITH CSV delimiter E'\t'  ESCAPE '\' QUOTE E'\b'  null as ''; 
-- '

CREATE INDEX idx_PaperExtendedAttributes_PaperId ON mag.PaperExtendedAttributes(PaperId);

--------------------------------------------------------
-- PaperUrls
--------------------------------------------------------
DROP TABLE IF EXISTS mag.PaperUrls;
CREATE TABLE mag.PaperUrls(
    id SERIAL PRIMARY KEY,
    PaperId BIGINT,
    SourceType SMALLINT,
    SourceUrl TEXT,
    LanguageCode VARCHAR(10)
  );

COPY mag.PaperUrls(PaperId, SourceType, SourceUrl, LanguageCode) FROM '/home/input/mag/PaperUrls.txt' WITH CSV delimiter E'\t'   QUOTE E'\b'  null as ''; 

CREATE INDEX idx_PaperUrls_PaperId ON mag.PaperUrls(PaperId);

--------------------------------------------------------
--------------------------------------------------------
-- MAG NLP
--------------------------------------------------------
--------------------------------------------------------

--------------------------------------------------------
-- PaperAbstractsInvertedIndex
--------------------------------------------------------

DROP TABLE IF EXISTS mag.PaperAbstractsInvertedIndex;
CREATE TABLE mag.PaperAbstractsInvertedIndex(
    PaperId BIGINT PRIMARY KEY,
    IndexedAbstract JSONB
  );

COPY mag.PaperAbstractsInvertedIndex(PaperId, IndexedAbstract) FROM '/home/input/nlp/PaperAbstractsInvertedIndex.txt.1' null as '';
COPY mag.PaperAbstractsInvertedIndex(PaperId, IndexedAbstract) FROM '/home/input/nlp/PaperAbstractsInvertedIndex.txt.2' null as '';

--------------------------------------------------------
-- PaperCitationContexts
--------------------------------------------------------
DROP TABLE IF EXISTS mag.PaperCitationContexts;
CREATE TABLE mag.PaperCitationContexts(
    id SERIAL PRIMARY KEY,
    PaperId BIGINT,
    PaperReferenceId BIGINT,
    CitationContext TEXT
  );

COPY mag.PaperCitationContexts(PaperId, PaperReferenceId, CitationContext) FROM '/home/input/nlp/PaperCitationContexts.txt' null as '';

CREATE INDEX idx_PaperCitationContexts_PaperId ON mag.PaperCitationContexts(PaperId);

--------------------------------------------------------
--------------------------------------------------------
-- MAG ADVANCED
--------------------------------------------------------
--------------------------------------------------------

--------------------------------------------------------
-- EntityRelatedEntities
--------------------------------------------------------
DROP TABLE IF EXISTS mag.EntityRelatedEntities;
CREATE TABLE mag.EntityRelatedEntities(
    id SERIAL PRIMARY KEY,
    EntityId BIGINT,
    EntityType VARCHAR(2),
    RelatedEntityId BIGINT,
    RelatedEntityType VARCHAR(2),
    RelatedType SMALLINT,
    Score FLOAT8
  );

COPY mag.EntityRelatedEntities(EntityId, EntityType, RelatedEntityId, RelatedEntityType, RelatedType, Score) FROM '/home/input/advanced/EntityRelatedEntities.txt' null as '';

CREATE INDEX idx_EntityRelatedEntities_EntityId ON mag.EntityRelatedEntities(EntityId);
CREATE INDEX idx_EntityRelatedEntities_RelatedEntityId ON mag.EntityRelatedEntities(RelatedEntityId);

--------------------------------------------------------
-- PaperRecommendations
--------------------------------------------------------
DROP TABLE IF EXISTS mag.PaperRecommendations;
CREATE TABLE mag.PaperRecommendations(
    id BIGSERIAL PRIMARY KEY,
    PaperId BIGINT,
    RecommendedPaperId BIGINT,
    Score FLOAT8
  );

COPY mag.PaperRecommendations(PaperId, RecommendedPaperId, Score) FROM '/home/input/advanced/PaperRecommendations.txt' null as '';

CREATE INDEX idx_PaperRecommendations_PaperId ON mag.PaperRecommendations(PaperId);
CREATE INDEX idx_PaperRecommendations_RecommendedPaperId ON mag.PaperRecommendations(RecommendedPaperId);

--------------------------------------------------------
-- PaperFieldsOfStudy
--------------------------------------------------------
DROP TABLE IF EXISTS mag.PaperFieldsOfStudy;
CREATE TABLE mag.PaperFieldsOfStudy(
    id SERIAL PRIMARY KEY,
    PaperId BIGINT,
    FieldOfStudyId BIGINT,
    Score FLOAT8
  );

COPY mag.PaperFieldsOfStudy(PaperId, FieldOfStudyId, Score) FROM '/home/input/advanced/PaperFieldsOfStudy.txt' null as '';

CREATE INDEX idx_PaperFieldsOfStudy_PaperId ON mag.PaperFieldsOfStudy(PaperId);
CREATE INDEX idx_PaperFieldsOfStudy_FieldOfStudyId ON mag.PaperFieldsOfStudy(FieldOfStudyId);

--------------------------------------------------------
-- FieldOfStudyChildren
--------------------------------------------------------
DROP TABLE IF EXISTS mag.FieldOfStudyChildren;
CREATE TABLE mag.FieldOfStudyChildren(
    id SERIAL PRIMARY KEY,
    FieldOfStudyId BIGINT,
    ChildFieldOfStudyId BIGINT
  );

COPY mag.FieldOfStudyChildren(FieldOfStudyId, ChildFieldOfStudyId) FROM '/home/input/advanced/FieldOfStudyChildren.txt' null as '';

CREATE INDEX idx_FieldOfStudyChildren_FieldOfStudyId ON mag.FieldOfStudyChildren(FieldOfStudyId);
CREATE INDEX idx_FieldOfStudyChildren_ChildFieldOfStudyId ON mag.FieldOfStudyChildren(ChildFieldOfStudyId);

--------------------------------------------------------
-- FieldOfStudyExtendedAttributes
--------------------------------------------------------
DROP TABLE IF EXISTS mag.FieldOfStudyExtendedAttributes;
CREATE TABLE mag.FieldOfStudyExtendedAttributes(
    id SERIAL PRIMARY KEY,
    FieldOfStudyId BIGINT,
    AttributeType SMALLINT,
    AttributeValue TEXT
  );

COPY mag.FieldOfStudyExtendedAttributes(FieldOfStudyId, AttributeType, AttributeValue) FROM '/home/input/advanced/FieldOfStudyExtendedAttributes.txt' null as '';

CREATE INDEX idx_FieldOfStudyExtendedAttributes_FieldOfStudyId ON mag.FieldOfStudyExtendedAttributes(FieldOfStudyId);

--------------------------------------------------------
-- FieldsOfStudy
--------------------------------------------------------
DROP TABLE IF EXISTS mag.FieldsOfStudy;
CREATE TABLE mag.FieldsOfStudy(
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

COPY mag.FieldsOfStudy(FieldOfStudyId, Rank, NormalizedName, DisplayName, MainType, Level, PaperCount, PaperFamilyCount, CitationCount, CreatedDate) FROM '/home/input/advanced/FieldsOfStudy.txt' null as '';

--------------------------------------------------------
-- RelatedFieldOfStudy
--------------------------------------------------------
DROP TABLE IF EXISTS mag.RelatedFieldOfStudy;
CREATE TABLE mag.RelatedFieldOfStudy(
    id SERIAL PRIMARY KEY,
    FieldOfStudyId1 BIGINT,
    Type1 VARCHAR(255),
    FieldOfStudyId2 BIGINT,
    Type2 VARCHAR(255),
    Rank FLOAT8
  );

COPY mag.RelatedFieldOfStudy(FieldOfStudyId1, Type1, FieldOfStudyId2, Type2, Rank) FROM '/home/input/advanced/RelatedFieldOfStudy.txt' null as '';

CREATE INDEX idx_RelatedFieldOfStudy_FieldOfStudyId1 ON mag.RelatedFieldOfStudy(FieldOfStudyId1);
CREATE INDEX idx_RelatedFieldOfStudy_FieldOfStudyId2 ON mag.RelatedFieldOfStudy(FieldOfStudyId2);
