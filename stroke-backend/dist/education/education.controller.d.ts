import { EducationService } from './education.service';
export declare class EducationController {
    private readonly educationService;
    constructor(educationService: EducationService);
    findAll(category?: string): Promise<{
        id: string;
        created_at: Date;
        content: string | null;
        media_url: string | null;
        title: string;
        category: string | null;
    }[]>;
    findOne(id: string): Promise<{
        id: string;
        created_at: Date;
        content: string | null;
        media_url: string | null;
        title: string;
        category: string | null;
    }>;
}
