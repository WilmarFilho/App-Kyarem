package com.nkw.backapisumula.social.service;

import com.nkw.backapisumula.cadastros.AtleticaMembro;
import com.nkw.backapisumula.cadastros.repo.AtleticaMembroRepository;
import com.nkw.backapisumula.common.outbox.EventPublisherService;
import com.nkw.backapisumula.identity.Profile;
import com.nkw.backapisumula.identity.repo.ProfileRepository;
import com.nkw.backapisumula.social.SocialComment;
import com.nkw.backapisumula.social.SocialCommentLike;
import com.nkw.backapisumula.social.SocialFollow;
import com.nkw.backapisumula.social.SocialPost;
import com.nkw.backapisumula.social.SocialPostLike;
import com.nkw.backapisumula.social.repo.SocialCommentLikeRepository;
import com.nkw.backapisumula.social.repo.SocialCommentRepository;
import com.nkw.backapisumula.social.repo.SocialFollowRepository;
import com.nkw.backapisumula.social.repo.SocialPostLikeRepository;
import com.nkw.backapisumula.social.repo.SocialPostRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class SocialService {

    private final SocialPostRepository socialPostRepository;
    private final SocialPostLikeRepository socialPostLikeRepository;
    private final SocialCommentRepository socialCommentRepository;
    private final SocialCommentLikeRepository socialCommentLikeRepository;
    private final SocialFollowRepository socialFollowRepository;
    private final ProfileRepository profileRepository;
    private final AtleticaMembroRepository atleticaMembroRepository;
    private final EventPublisherService eventPublisherService;

    public SocialService(
            SocialPostRepository socialPostRepository,
            SocialPostLikeRepository socialPostLikeRepository,
            SocialCommentRepository socialCommentRepository,
            SocialCommentLikeRepository socialCommentLikeRepository,
            SocialFollowRepository socialFollowRepository,
            ProfileRepository profileRepository,
            AtleticaMembroRepository atleticaMembroRepository,
            EventPublisherService eventPublisherService
    ) {
        this.socialPostRepository = socialPostRepository;
        this.socialPostLikeRepository = socialPostLikeRepository;
        this.socialCommentRepository = socialCommentRepository;
        this.socialCommentLikeRepository = socialCommentLikeRepository;
        this.socialFollowRepository = socialFollowRepository;
        this.profileRepository = profileRepository;
        this.atleticaMembroRepository = atleticaMembroRepository;
        this.eventPublisherService = eventPublisherService;
    }

    @Transactional(readOnly = true)
    public List<FeedPostView> getFeed(UUID viewerUserId, int limit) {
        int safeLimit = Math.max(1, Math.min(limit, 50));
        List<SocialPost> posts = socialPostRepository.findFeedPosts(viewerUserId, PageRequest.of(0, safeLimit));
        return buildPostViews(posts, viewerUserId);
    }

    @Transactional(readOnly = true)
    public List<FeedPostView> getProfilePosts(UUID profileUserId, UUID viewerUserId, int limit) {
        int safeLimit = Math.max(1, Math.min(limit, 50));
        List<SocialPost> posts = socialPostRepository.findProfilePosts(profileUserId, PageRequest.of(0, safeLimit));
        return buildPostViews(posts, viewerUserId);
    }

    @Transactional(readOnly = true)
    public PublicProfileView getPublicProfile(UUID profileUserId, UUID viewerUserId) {
        Profile profile = getProfileOrThrow(profileUserId);
        AtleticaMembro primaryMembership = resolvePrimaryMembership(profileUserId);
        return new PublicProfileView(
                profile.getId(),
                coalesceProfileName(profile),
                profile.getFotoUrl(),
                profile.getGenero(),
                primaryMembership != null ? primaryMembership.getAtletica().getId() : null,
                primaryMembership != null ? primaryMembership.getAtletica().getNome() : null,
                primaryMembership != null ? primaryMembership.getPapelCodigo() : null,
                socialPostRepository.countByAuthor_Id(profileUserId),
                socialFollowRepository.countByFollowed_Id(profileUserId),
                socialFollowRepository.countByFollower_Id(profileUserId),
                viewerUserId != null && socialFollowRepository.existsByFollower_IdAndFollowed_Id(viewerUserId, profileUserId)
        );
    }

    @Transactional
    public FeedPostView createPost(UUID authorUserId, CreatePostCommand command) {
        Profile author = getProfileOrThrow(authorUserId);
        validatePostPayload(command.content(), command.imageUrl());

        OffsetDateTime now = OffsetDateTime.now();
        SocialPost post = new SocialPost();
        post.setId(UUID.randomUUID());
        post.setAuthor(author);
        post.setContent(normalizeNullable(command.content()));
        post.setImageUrl(normalizeNullable(command.imageUrl()));
        post.setLikeCount(0);
        post.setCommentCount(0);
        post.setCreatedAt(now);
        post.setUpdatedAt(now);
        socialPostRepository.save(post);

        publishSocialEvent(
                "SocialPost",
                post.getId(),
                "SocialPostCriado",
                Map.of(
                        "postId", post.getId().toString(),
                        "authorUserId", authorUserId.toString()
                )
        );

        return buildPostViews(List.of(post), authorUserId).get(0);
    }

    @Transactional
    public FeedPostView likePost(UUID postId, UUID userId) {
        SocialPost post = getPostOrThrow(postId);
        if (!socialPostLikeRepository.existsByPost_IdAndUser_Id(postId, userId)) {
            SocialPostLike like = new SocialPostLike();
            like.setId(UUID.randomUUID());
            like.setPost(post);
            like.setUser(getProfileOrThrow(userId));
            like.setCreatedAt(OffsetDateTime.now());
            socialPostLikeRepository.save(like);

            post.setLikeCount(post.getLikeCount() + 1);
            post.setUpdatedAt(OffsetDateTime.now());
            socialPostRepository.save(post);

            publishSocialEvent(
                    "SocialPost",
                    post.getId(),
                    "SocialPostCurtido",
                    Map.of(
                            "postId", postId.toString(),
                            "authorUserId", post.getAuthor().getId().toString(),
                            "actorUserId", userId.toString()
                    )
            );
        }
        return buildPostViews(List.of(post), userId).get(0);
    }

    @Transactional
    public FeedPostView unlikePost(UUID postId, UUID userId) {
        SocialPost post = getPostOrThrow(postId);
        socialPostLikeRepository.findByPost_IdAndUser_Id(postId, userId).ifPresent(like -> {
            socialPostLikeRepository.delete(like);
            post.setLikeCount(Math.max(0, post.getLikeCount() - 1));
            post.setUpdatedAt(OffsetDateTime.now());
            socialPostRepository.save(post);
            publishSocialEvent(
                    "SocialPost",
                    post.getId(),
                    "SocialPostDescurtido",
                    Map.of(
                            "postId", postId.toString(),
                            "authorUserId", post.getAuthor().getId().toString(),
                            "actorUserId", userId.toString()
                    )
            );
        });
        return buildPostViews(List.of(post), userId).get(0);
    }

    @Transactional(readOnly = true)
    public List<CommentView> listComments(UUID postId, UUID viewerUserId) {
        getPostOrThrow(postId);
        return buildCommentTree(socialCommentRepository.findByPost_IdOrderByCreatedAtAsc(postId), viewerUserId);
    }

    @Transactional
    public CommentView createComment(UUID postId, UUID authorUserId, CreateCommentCommand command) {
        SocialPost post = getPostOrThrow(postId);
        Profile author = getProfileOrThrow(authorUserId);
        String content = normalizeRequired(command.content(), "Comentário é obrigatório.");

        SocialComment parent = null;
        if (command.parentCommentId() != null) {
            parent = socialCommentRepository.findById(command.parentCommentId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Comentário pai não encontrado."));
            if (!parent.getPost().getId().equals(postId)) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Comentário pai inválido para este post.");
            }
        }

        OffsetDateTime now = OffsetDateTime.now();
        SocialComment comment = new SocialComment();
        comment.setId(UUID.randomUUID());
        comment.setPost(post);
        comment.setAuthor(author);
        comment.setParentComment(parent);
        comment.setContent(content);
        comment.setLikeCount(0);
        comment.setReplyCount(0);
        comment.setCreatedAt(now);
        comment.setUpdatedAt(now);
        socialCommentRepository.save(comment);

        post.setCommentCount(post.getCommentCount() + 1);
        post.setUpdatedAt(now);
        socialPostRepository.save(post);

        if (parent != null) {
            parent.setReplyCount(parent.getReplyCount() + 1);
            parent.setUpdatedAt(now);
            socialCommentRepository.save(parent);
        }

        publishSocialEvent(
                "SocialComment",
                comment.getId(),
                "SocialComentarioCriado",
                Map.of(
                        "postId", postId.toString(),
                        "commentId", comment.getId().toString(),
                        "authorUserId", authorUserId.toString(),
                        "postAuthorUserId", post.getAuthor().getId().toString()
                )
        );

        return toCommentView(comment, authorUserId, List.of());
    }

    @Transactional
    public CommentView likeComment(UUID commentId, UUID userId) {
        SocialComment comment = getCommentOrThrow(commentId);
        if (!socialCommentLikeRepository.existsByComment_IdAndUser_Id(commentId, userId)) {
            SocialCommentLike like = new SocialCommentLike();
            like.setId(UUID.randomUUID());
            like.setComment(comment);
            like.setUser(getProfileOrThrow(userId));
            like.setCreatedAt(OffsetDateTime.now());
            socialCommentLikeRepository.save(like);

            comment.setLikeCount(comment.getLikeCount() + 1);
            comment.setUpdatedAt(OffsetDateTime.now());
            socialCommentRepository.save(comment);

            publishSocialEvent(
                    "SocialComment",
                    comment.getId(),
                    "SocialComentarioCurtido",
                    Map.of(
                            "commentId", commentId.toString(),
                            "postId", comment.getPost().getId().toString(),
                            "actorUserId", userId.toString()
                    )
            );
        }
        return toCommentView(comment, userId, List.of());
    }

    @Transactional
    public CommentView unlikeComment(UUID commentId, UUID userId) {
        SocialComment comment = getCommentOrThrow(commentId);
        socialCommentLikeRepository.findByComment_IdAndUser_Id(commentId, userId).ifPresent(like -> {
            socialCommentLikeRepository.delete(like);
            comment.setLikeCount(Math.max(0, comment.getLikeCount() - 1));
            comment.setUpdatedAt(OffsetDateTime.now());
            socialCommentRepository.save(comment);
            publishSocialEvent(
                    "SocialComment",
                    comment.getId(),
                    "SocialComentarioDescurtido",
                    Map.of(
                            "commentId", commentId.toString(),
                            "postId", comment.getPost().getId().toString(),
                            "actorUserId", userId.toString()
                    )
            );
        });
        return toCommentView(comment, userId, List.of());
    }

    @Transactional
    public PublicProfileView follow(UUID targetUserId, UUID followerUserId) {
        if (targetUserId.equals(followerUserId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Você não pode seguir o próprio perfil.");
        }

        Profile follower = getProfileOrThrow(followerUserId);
        Profile followed = getProfileOrThrow(targetUserId);

        if (!socialFollowRepository.existsByFollower_IdAndFollowed_Id(followerUserId, targetUserId)) {
            SocialFollow follow = new SocialFollow();
            follow.setId(UUID.randomUUID());
            follow.setFollower(follower);
            follow.setFollowed(followed);
            follow.setCreatedAt(OffsetDateTime.now());
            socialFollowRepository.save(follow);

            publishSocialEvent(
                    "SocialFollow",
                    follow.getId(),
                    "SocialSeguidorCriado",
                    Map.of(
                            "followedUserId", targetUserId.toString(),
                            "followerUserId", followerUserId.toString()
                    )
            );
        }

        return getPublicProfile(targetUserId, followerUserId);
    }

    @Transactional
    public PublicProfileView unfollow(UUID targetUserId, UUID followerUserId) {
        socialFollowRepository.findByFollower_IdAndFollowed_Id(followerUserId, targetUserId).ifPresent(follow -> {
            socialFollowRepository.delete(follow);
            publishSocialEvent(
                    "SocialFollow",
                    follow.getId(),
                    "SocialSeguidorRemovido",
                    Map.of(
                            "followedUserId", targetUserId.toString(),
                            "followerUserId", followerUserId.toString()
                    )
            );
        });
        return getPublicProfile(targetUserId, followerUserId);
    }

    private List<FeedPostView> buildPostViews(List<SocialPost> posts, UUID viewerUserId) {
        List<FeedPostView> result = new ArrayList<>();
        for (SocialPost post : posts) {
            List<SocialComment> postComments = socialCommentRepository.findByPost_IdAndParentCommentIsNullOrderByCreatedAtAsc(post.getId());
            List<SocialComment> previewComments = postComments.stream()
                    .sorted(Comparator.comparing(SocialComment::getCreatedAt))
                    .limit(2)
                    .toList();
            List<CommentView> preview = buildCommentTree(previewComments, viewerUserId);

            AtleticaMembro membership = resolvePrimaryMembership(post.getAuthor().getId());
            result.add(new FeedPostView(
                    post.getId(),
                    toAuthorView(post.getAuthor(), membership),
                    normalizeNullable(post.getContent()),
                    normalizeNullable(post.getImageUrl()),
                    post.getLikeCount(),
                    post.getCommentCount(),
                    socialPostLikeRepository.existsByPost_IdAndUser_Id(post.getId(), viewerUserId),
                    post.getCreatedAt(),
                    preview
            ));
        }
        return result;
    }

    private List<CommentView> buildCommentTree(List<SocialComment> comments, UUID viewerUserId) {
        Map<UUID, List<SocialComment>> repliesByParentId = new HashMap<>();
        List<SocialComment> roots = new ArrayList<>();

        for (SocialComment comment : comments) {
            if (comment.getParentComment() == null) {
                roots.add(comment);
            } else {
                repliesByParentId.computeIfAbsent(comment.getParentComment().getId(), ignored -> new ArrayList<>())
                        .add(comment);
            }
        }

        roots.sort(Comparator.comparing(SocialComment::getCreatedAt));
        repliesByParentId.values().forEach(list -> list.sort(Comparator.comparing(SocialComment::getCreatedAt)));

        List<CommentView> result = new ArrayList<>();
        for (SocialComment root : roots) {
            List<CommentView> replies = repliesByParentId.getOrDefault(root.getId(), List.of()).stream()
                    .map(reply -> toCommentView(reply, viewerUserId, List.of()))
                    .toList();
            result.add(toCommentView(root, viewerUserId, replies));
        }
        return result;
    }

    private CommentView toCommentView(SocialComment comment, UUID viewerUserId, List<CommentView> replies) {
        AtleticaMembro membership = resolvePrimaryMembership(comment.getAuthor().getId());
        return new CommentView(
                comment.getId(),
                toAuthorView(comment.getAuthor(), membership),
                comment.getContent(),
                comment.getLikeCount(),
                comment.getReplyCount(),
                viewerUserId != null && socialCommentLikeRepository.existsByComment_IdAndUser_Id(comment.getId(), viewerUserId),
                comment.getCreatedAt(),
                comment.getParentComment() != null ? comment.getParentComment().getId() : null,
                replies
        );
    }

    private AuthorView toAuthorView(Profile profile, AtleticaMembro membership) {
        return new AuthorView(
                profile.getId(),
                coalesceProfileName(profile),
                profile.getFotoUrl(),
                membership != null ? membership.getAtletica().getId() : null,
                membership != null ? membership.getAtletica().getNome() : null,
                membership != null ? membership.getPapelCodigo() : null
        );
    }

    private void validatePostPayload(String rawContent, String rawImageUrl) {
        String content = normalizeNullable(rawContent);
        String imageUrl = normalizeNullable(rawImageUrl);
        if ((content == null || content.isBlank()) && (imageUrl == null || imageUrl.isBlank())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "O post precisa ter texto, imagem ou ambos.");
        }
        if (content != null && content.length() > 2000) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "O texto do post deve ter no máximo 2000 caracteres.");
        }
    }

    private String normalizeRequired(String rawValue, String message) {
        String normalized = normalizeNullable(rawValue);
        if (normalized == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
        }
        return normalized;
    }

    private String normalizeNullable(String rawValue) {
        if (rawValue == null) {
            return null;
        }
        String value = rawValue.trim();
        return value.isBlank() ? null : value;
    }

    private SocialPost getPostOrThrow(UUID postId) {
        return socialPostRepository.findById(postId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Post não encontrado."));
    }

    private SocialComment getCommentOrThrow(UUID commentId) {
        return socialCommentRepository.findById(commentId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Comentário não encontrado."));
    }

    private Profile getProfileOrThrow(UUID profileId) {
        return profileRepository.findById(profileId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Perfil não encontrado."));
    }

    private AtleticaMembro resolvePrimaryMembership(UUID profileUserId) {
        return atleticaMembroRepository.findByUser_IdAndStatusOrderByCriadoEmAsc(profileUserId, "ATIVO")
                .stream()
                .findFirst()
                .orElse(null);
    }

    private String coalesceProfileName(Profile profile) {
        if (profile.getNomeExibicao() != null && !profile.getNomeExibicao().isBlank()) {
            return profile.getNomeExibicao();
        }
        if (profile.getNomeCompleto() != null && !profile.getNomeCompleto().isBlank()) {
            return profile.getNomeCompleto();
        }
        return "Usuário";
    }

    private void publishSocialEvent(String aggregateType, UUID aggregateId, String eventType, Map<String, Object> payload) {
        Map<String, Object> enriched = new LinkedHashMap<>(payload);
        enriched.put("socialChannel", "feed");
        eventPublisherService.publish(aggregateType, aggregateId.toString(), eventType, enriched);
    }

    public record CreatePostCommand(String content, String imageUrl) {}

    public record CreateCommentCommand(String content, UUID parentCommentId) {}

    public record AuthorView(
            UUID id,
            String nomeExibicao,
            String fotoUrl,
            UUID atleticaId,
            String atleticaNome,
            String papelCodigo
    ) {}

    public record CommentView(
            UUID id,
            AuthorView author,
            String content,
            int likeCount,
            int replyCount,
            boolean likedByMe,
            OffsetDateTime createdAt,
            UUID parentCommentId,
            List<CommentView> replies
    ) {}

    public record FeedPostView(
            UUID id,
            AuthorView author,
            String content,
            String imageUrl,
            int likeCount,
            int commentCount,
            boolean likedByMe,
            OffsetDateTime createdAt,
            List<CommentView> commentPreview
    ) {}

    public record PublicProfileView(
            UUID id,
            String nomeExibicao,
            String fotoUrl,
            String genero,
            UUID atleticaId,
            String atleticaNome,
            String papelCodigo,
            long postCount,
            long followerCount,
            long followingCount,
            boolean following
    ) {}
}
