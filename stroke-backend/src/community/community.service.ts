import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Post, Comment, Prisma } from '@prisma/client';

@Injectable()
export class CommunityService {
    constructor(private prisma: PrismaService) { }

    /**
     * Mengambil semua postingan dengan jumlah like dan komentar
     */
    async findAllPosts(): Promise<Post[]> {
        return this.prisma.post.findMany({
            include: {
                user: {
                    select: {
                        full_name: true,
                        photo_url: true,
                    },
                },
                _count: {
                    select: {
                        comments: true,
                        likes: true,
                    },
                },
            },
            orderBy: { created_at: 'desc' },
        });
    }

    /**
     * Membuat postingan baru
     * @param data Data postingan
     */
    async createPost(data: Prisma.PostCreateInput): Promise<Post> {
        return this.prisma.post.create({
            data,
        });
    }

    /**
     * Menambahkan komentar pada postingan
     * @param postId ID postingan
     * @param userId ID user yang berkomentar
     * @param content Isi komentar
     */
    async addComment(postId: string, userId: string, content: string): Promise<Comment> {
        return this.prisma.comment.create({
            data: {
                post_id: postId,
                user_id: userId,
                content: content,
            },
        });
    }

    /**
     * Menyukai postingan (Like)
     * @param postId ID postingan
     * @param userId ID user yang menyukai
     */
    async likePost(postId: string, userId: string) {
        return this.prisma.like.create({
            data: {
                post_id: postId,
                user_id: userId,
            },
        });
    }
}
