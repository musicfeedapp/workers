defmodule Requesters.Repo.Migrations.AddUsers do
  use Ecto.Migration

  def up do
    execute """
      CREATE EXTENSION hstore;
    """

    execute """
CREATE TABLE users (
    id integer NOT NULL,
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(255) DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    role character varying(255),
    avatar character varying(255),
    first_name character varying(255),
    middle_name character varying(255),
    last_name character varying(255),
    facebook_link character varying(255),
    twitter_link character varying(255),
    google_plus_link character varying(255),
    linkedin_link character varying(255),
    facebook_avatar character varying(255),
    google_plus_avatar character varying(255),
    linkedin_avatar character varying(255),
    authentication_token character varying(255),
    facebook_profile_image_url character varying(255),
    facebook_id character varying(255),
    background character varying(255),
    username character varying,
    comments_count integer DEFAULT 0,
    enabled boolean DEFAULT true,
    website text DEFAULT '0'::text,
    genres text[] DEFAULT '{}'::text[],
    user_type character varying(255) DEFAULT 'user'::character varying NOT NULL,
    followers_count integer DEFAULT 0,
    followed_count integer DEFAULT 0,
    friends_count integer DEFAULT 0,
    name character varying(255) NOT NULL,
    is_verified boolean DEFAULT false,
    ext_id character varying,
    restricted_timelines integer[] DEFAULT '{}'::integer[],
    restricted_users character varying[] DEFAULT '{}'::character varying[],
    welcome_notified_at timestamp without time zone,
    category character varying,
    public_playlists_timelines_count integer DEFAULT 0,
    private_playlists_timelines_count integer DEFAULT 0,
    aggregated_at timestamp without time zone,
    suggestions_count integer DEFAULT 0,
    contact_number character varying,
    contact_list hstore[] DEFAULT '{}'::hstore[],
    phone_artists hstore[] DEFAULT '{}'::hstore[],
    device_id character varying,
    last_feed_viewed_at timestamp without time zone DEFAULT '2015-12-03 09:09:51.499422'::timestamp without time zone,
    secondary_emails text[] DEFAULT '{}'::text[],
    secondary_phones text[] DEFAULT '{}'::text[],
    login_method character varying,
    timelines_count integer DEFAULT 0,
    restricted_suggestions text[] DEFAULT '{}'::text[]
);
    """

    execute """
CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
    """

    execute """
ALTER SEQUENCE users_id_seq OWNED BY users.id;
    """

    execute """
ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);
    """

    execute """
ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
    """

    execute """
CREATE UNIQUE INDEX index_users_on_authentication_token ON users USING btree (authentication_token);
    """

    execute """
CREATE INDEX index_users_on_category ON users USING btree (category);
    """

    execute """
CREATE INDEX index_users_on_created_at ON users USING btree (created_at);
    """

    execute """
CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);
    """

    execute """
CREATE INDEX index_users_on_enabled ON users USING btree (enabled);
    """

    execute """
CREATE INDEX index_users_on_ext_id ON users USING btree (ext_id);
    """

    execute """
CREATE INDEX index_users_on_facebook_id ON users USING btree (facebook_id);
    """

    execute """
CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);
    """

    execute """
CREATE INDEX index_users_on_user_type ON users USING btree (user_type);
    """

    execute """
CREATE INDEX index_users_on_username ON users USING btree (username);
    """
  end

  def down do
    execute """
      DROP TABLE users;
    """
  end
end
