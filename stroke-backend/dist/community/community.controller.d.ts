import { CommunityService } from './community.service';
import { Prisma } from '@prisma/client';
export declare class CommunityController {
    private readonly communityService;
    constructor(communityService: CommunityService);
    findAllPosts(): Promise<{
        id: string;
        created_at: Date;
        user_id: string | null;
        content: string | null;
        media_url: string | null;
        media_type: string | null;
        like_count: number;
        comment_count: number;
    }[]>;
    createPost(data: Prisma.PostCreateInput): Promise<{
        id: string;
        created_at: Date;
        user_id: string | null;
        content: string | null;
        media_url: string | null;
        media_type: string | null;
        like_count: number;
        comment_count: number;
    }>;
    addComment(postId: string, userId: string, content: string): Promise<{
        id: string;
        created_at: Date;
        user_id: string | null;
        content: string | null;
        post_id: string | null;
    }>;
    likePost(postId: string, userId: string): Promise<{
        id: string;
        created_at: Date;
        user_id: string | null;
        post_id: string | null;
    }>;
}
