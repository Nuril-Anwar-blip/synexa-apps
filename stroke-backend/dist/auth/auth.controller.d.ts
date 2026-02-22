import { AuthService } from './auth.service';
export declare class AuthController {
    private authService;
    constructor(authService: AuthService);
    register(body: Record<string, any>): Promise<{
        id: string;
        email: string | null;
        password: string;
        full_name: string;
        phone_number: string;
        age: number;
        height: number;
        weight: number;
        gender: string;
        medical_history: import("@prisma/client/runtime/library").JsonValue;
        drug_allergy: import("@prisma/client/runtime/library").JsonValue;
        emergency_contact: import("@prisma/client/runtime/library").JsonValue;
        photo_url: string | null;
        role: import(".prisma/client").$Enums.Role;
        created_at: Date;
    }>;
    login(body: Record<string, any>): Promise<{
        access_token: string;
        user: {
            id: string;
            email: string | null;
            password: string;
            full_name: string;
            phone_number: string;
            age: number;
            height: number;
            weight: number;
            gender: string;
            medical_history: import("@prisma/client/runtime/library").JsonValue;
            drug_allergy: import("@prisma/client/runtime/library").JsonValue;
            emergency_contact: import("@prisma/client/runtime/library").JsonValue;
            photo_url: string | null;
            role: import(".prisma/client").$Enums.Role;
            created_at: Date;
        };
    }>;
}
