-- =============================================================================
-- V41 - Rede social operacional do app geral de esportes
-- =============================================================================

CREATE TABLE IF NOT EXISTS operational.social_posts (
    id              UUID         PRIMARY KEY,
    author_user_id  UUID         NOT NULL REFERENCES operational.profiles(id) ON DELETE CASCADE,
    content         TEXT,
    image_url       VARCHAR(1000),
    like_count      INTEGER      NOT NULL DEFAULT 0,
    comment_count   INTEGER      NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT ck_social_posts_content_or_image
        CHECK (
            (content IS NOT NULL AND length(trim(content)) > 0)
            OR (image_url IS NOT NULL AND length(trim(image_url)) > 0)
        )
);

CREATE INDEX IF NOT EXISTS idx_social_posts_author_created
    ON operational.social_posts (author_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_social_posts_created
    ON operational.social_posts (created_at DESC);

CREATE TABLE IF NOT EXISTS operational.social_post_likes (
    id              UUID         PRIMARY KEY,
    post_id         UUID         NOT NULL REFERENCES operational.social_posts(id) ON DELETE CASCADE,
    user_id         UUID         NOT NULL REFERENCES operational.profiles(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT uk_social_post_likes UNIQUE (post_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_social_post_likes_post
    ON operational.social_post_likes (post_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_social_post_likes_user
    ON operational.social_post_likes (user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS operational.social_comments (
    id                  UUID         PRIMARY KEY,
    post_id             UUID         NOT NULL REFERENCES operational.social_posts(id) ON DELETE CASCADE,
    author_user_id      UUID         NOT NULL REFERENCES operational.profiles(id) ON DELETE CASCADE,
    parent_comment_id   UUID         REFERENCES operational.social_comments(id) ON DELETE CASCADE,
    content             TEXT         NOT NULL,
    like_count          INTEGER      NOT NULL DEFAULT 0,
    reply_count         INTEGER      NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT ck_social_comments_content
        CHECK (length(trim(content)) > 0)
);

CREATE INDEX IF NOT EXISTS idx_social_comments_post_created
    ON operational.social_comments (post_id, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_social_comments_parent_created
    ON operational.social_comments (parent_comment_id, created_at ASC);

CREATE TABLE IF NOT EXISTS operational.social_comment_likes (
    id              UUID         PRIMARY KEY,
    comment_id      UUID         NOT NULL REFERENCES operational.social_comments(id) ON DELETE CASCADE,
    user_id         UUID         NOT NULL REFERENCES operational.profiles(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT uk_social_comment_likes UNIQUE (comment_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_social_comment_likes_comment
    ON operational.social_comment_likes (comment_id, created_at DESC);

CREATE TABLE IF NOT EXISTS operational.social_follows (
    id                  UUID         PRIMARY KEY,
    follower_user_id    UUID         NOT NULL REFERENCES operational.profiles(id) ON DELETE CASCADE,
    followed_user_id    UUID         NOT NULL REFERENCES operational.profiles(id) ON DELETE CASCADE,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT uk_social_follows UNIQUE (follower_user_id, followed_user_id),
    CONSTRAINT ck_social_follows_not_self
        CHECK (follower_user_id <> followed_user_id)
);

CREATE INDEX IF NOT EXISTS idx_social_follows_follower
    ON operational.social_follows (follower_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_social_follows_followed
    ON operational.social_follows (followed_user_id, created_at DESC);

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'social-posts',
    'social-posts',
    true,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE
    SET public = EXCLUDED.public,
        file_size_limit = EXCLUDED.file_size_limit,
        allowed_mime_types = EXCLUDED.allowed_mime_types;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage'
          AND tablename  = 'objects'
          AND policyname = 'social_posts_public_read'
    ) THEN
        CREATE POLICY "social_posts_public_read" ON storage.objects
            FOR SELECT TO public
            USING (bucket_id = 'social-posts');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage'
          AND tablename  = 'objects'
          AND policyname = 'social_posts_insert_owner'
    ) THEN
        CREATE POLICY "social_posts_insert_owner" ON storage.objects
            FOR INSERT TO authenticated
            WITH CHECK (
                bucket_id = 'social-posts'
                AND (auth.uid())::text = (storage.foldername(name))[1]
            );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage'
          AND tablename  = 'objects'
          AND policyname = 'social_posts_update_owner'
    ) THEN
        CREATE POLICY "social_posts_update_owner" ON storage.objects
            FOR UPDATE TO authenticated
            USING (
                bucket_id = 'social-posts'
                AND (auth.uid())::text = (storage.foldername(name))[1]
            );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage'
          AND tablename  = 'objects'
          AND policyname = 'social_posts_delete_owner'
    ) THEN
        CREATE POLICY "social_posts_delete_owner" ON storage.objects
            FOR DELETE TO authenticated
            USING (
                bucket_id = 'social-posts'
                AND (auth.uid())::text = (storage.foldername(name))[1]
            );
    END IF;
END $$;
