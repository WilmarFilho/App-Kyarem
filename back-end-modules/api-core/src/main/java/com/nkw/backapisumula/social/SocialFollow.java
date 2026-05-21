package com.nkw.backapisumula.social;

import com.nkw.backapisumula.identity.Profile;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "social_follows", schema = "operational")
public class SocialFollow {

    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "follower_user_id", nullable = false)
    private Profile follower;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "followed_user_id", nullable = false)
    private Profile followed;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt;

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public Profile getFollower() {
        return follower;
    }

    public void setFollower(Profile follower) {
        this.follower = follower;
    }

    public Profile getFollowed() {
        return followed;
    }

    public void setFollowed(Profile followed) {
        this.followed = followed;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
