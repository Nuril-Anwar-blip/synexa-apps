import { PrismaService } from '../prisma/prisma.service';
import { Post, Comment, Prisma } from '@prisma/client';
export declare class CommunityService {
    private prisma;
    constructor(prisma: PrismaService);
    findAllPosts(): Promise<Post[]>;
    createPost(data: Prisma.PostCreateInput): Promise<Post>;
    addComment(postId: string, userId: string, content: string): Promise<Comment>;
    likePost(postId: string, userId: string): Promise<{
        id: string;
        created_at: Date;
        user_id: string | null;
        post_id: string | null;
    }>;
}
