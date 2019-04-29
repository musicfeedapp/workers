defmodule Requesters.Repo.Migrations.AddTimelines do
  use Ecto.Migration

  def up do
    execute """
      CREATE TABLE timelines (
          id integer NOT NULL,
          name character varying(255),
          description text,
          link text,
          picture text,
          created_at timestamp without time zone,
          updated_at timestamp without time zone,
          feed_type character varying(255) NOT NULL,
          identifier character varying(255),
          likes_count integer DEFAULT 0,
          published_at timestamp without time zone,
          youtube_id character varying(255),
          enabled boolean DEFAULT true,
          artist character varying(255),
          album character varying(255),
          source character varying(255),
          source_link text,
          youtube_link character varying(255),
          restricted_users integer[] DEFAULT '{}'::integer[],
          likes integer[] DEFAULT '{}'::integer[],
          font_color character varying,
          genres character varying[] DEFAULT '{}'::character varying[],
          comments_count integer DEFAULT 0,
          itunes_link character varying,
          stream text,
          default_playlist_user_ids integer[] DEFAULT '{}'::integer[],
          activities_count integer DEFAULT 0,
          import_source character varying DEFAULT 'feed'::character varying,
          category character varying,
          view_count integer DEFAULT 0,
          change_view_count integer DEFAULT 0
      );
    """

    execute """
      CREATE SEQUENCE timelines_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;
    """

    execute """
      ALTER SEQUENCE timelines_id_seq OWNED BY timelines.id;
    """

    execute """
      ALTER TABLE ONLY timelines ALTER COLUMN id SET DEFAULT nextval('timelines_id_seq'::regclass);
    """

    execute """
      ALTER TABLE ONLY timelines
          ADD CONSTRAINT timelines_pkey PRIMARY KEY (id);
    """

    execute """
      CREATE INDEX index_timelines_on_created_at ON timelines USING btree (created_at);
    """

    execute """
      CREATE INDEX index_timelines_on_feed_type ON timelines USING btree (feed_type);
    """

    execute """
      CREATE INDEX index_timelines_on_id_asc ON timelines USING btree (id);
    """

    execute """
      CREATE INDEX index_timelines_on_identifier ON timelines USING btree (identifier);
    """

    execute """
      CREATE INDEX index_timelines_on_published_at_desc ON timelines USING btree (published_at DESC NULLS LAST);
    """

    execute """
      CREATE INDEX index_timelines_on_source_link ON timelines USING btree (source_link);
    """

    execute """
      CREATE UNIQUE INDEX index_timelines_on_youtube_link ON timelines USING btree (youtube_link);
    """

    execute """
      CREATE INDEX index_timelines_on_youtube_link_and_source_link_and_identifier ON timelines USING btree (youtube_link, source_link, identifier);
    """
  end

  def down do
    execute """
      DROP TABLE timelines;
    """
  end
end
