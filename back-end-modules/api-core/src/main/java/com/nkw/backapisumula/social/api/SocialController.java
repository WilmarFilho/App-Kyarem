package com.nkw.backapisumula.social.api;

import com.nkw.backapisumula.social.service.SocialService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@Validated
@RequestMapping("/api/v1/social")
@PreAuthorize("isAuthenticated()")
public class SocialController {

    private final SocialService socialService;

    public SocialController(SocialService socialService) {
        this.socialService = socialService;
    }

    @GetMapping("/feed")
    public List<SocialService.FeedPostView> feed(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(defaultValue = "20") int limit
    ) {
        return socialService.getFeed(currentUserId(jwt), limit);
    }

    @PostMapping("/posts")
    @ResponseStatus(HttpStatus.CREATED)
    public SocialService.FeedPostView createPost(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody CreatePostRequest request
    ) {
        return socialService.createPost(
                currentUserId(jwt),
                new SocialService.CreatePostCommand(request.content(), request.imageUrl())
        );
    }

    @PostMapping("/posts/{postId}/likes")
    public SocialService.FeedPostView likePost(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID postId
    ) {
        return socialService.likePost(postId, currentUserId(jwt));
    }

    @DeleteMapping("/posts/{postId}/likes")
    public SocialService.FeedPostView unlikePost(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID postId
    ) {
        return socialService.unlikePost(postId, currentUserId(jwt));
    }

    @GetMapping("/posts/{postId}/comments")
    public List<SocialService.CommentView> comments(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID postId
    ) {
        return socialService.listComments(postId, currentUserId(jwt));
    }

    @PostMapping("/posts/{postId}/comments")
    @ResponseStatus(HttpStatus.CREATED)
    public SocialService.CommentView createComment(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID postId,
            @Valid @RequestBody CreateCommentRequest request
    ) {
        return socialService.createComment(
                postId,
                currentUserId(jwt),
                new SocialService.CreateCommentCommand(request.content(), request.parentCommentId())
        );
    }

    @PostMapping("/comments/{commentId}/likes")
    public SocialService.CommentView likeComment(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID commentId
    ) {
        return socialService.likeComment(commentId, currentUserId(jwt));
    }

    @DeleteMapping("/comments/{commentId}/likes")
    public SocialService.CommentView unlikeComment(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID commentId
    ) {
        return socialService.unlikeComment(commentId, currentUserId(jwt));
    }

    @GetMapping("/profiles/{profileId}")
    public SocialService.PublicProfileView publicProfile(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID profileId
    ) {
        return socialService.getPublicProfile(profileId, currentUserId(jwt));
    }

    @GetMapping("/profiles/{profileId}/posts")
    public List<SocialService.FeedPostView> profilePosts(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID profileId,
            @RequestParam(defaultValue = "20") int limit
    ) {
        return socialService.getProfilePosts(profileId, currentUserId(jwt), limit);
    }

    @PostMapping("/profiles/{profileId}/follow")
    public SocialService.PublicProfileView follow(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID profileId
    ) {
        return socialService.follow(profileId, currentUserId(jwt));
    }

    @DeleteMapping("/profiles/{profileId}/follow")
    public SocialService.PublicProfileView unfollow(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID profileId
    ) {
        return socialService.unfollow(profileId, currentUserId(jwt));
    }

    private UUID currentUserId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }

    public record CreatePostRequest(
            @Size(max = 2000) String content,
            String imageUrl
    ) {}

    public record CreateCommentRequest(
            @Size(max = 1000) String content,
            UUID parentCommentId
    ) {}
}
