import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import { User, Prisma } from '@prisma/client';
export declare class AuthService {
    private usersService;
    private jwtService;
    constructor(usersService: UsersService, jwtService: JwtService);
    validateUser(email: string, pass: string): Promise<any>;
    login(user: User): {
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
            medical_history: Prisma.JsonValue;
            drug_allergy: Prisma.JsonValue;
            emergency_contact: Prisma.JsonValue;
            photo_url: string | null;
            role: import(".prisma/client").$Enums.Role;
            created_at: Date;
        };
    };
    register(data: Record<string, any>): Promise<{
        id: string;
        email: string | null;
        password: string;
        full_name: string;
        phone_number: string;
        age: number;
        height: number;
        weight: number;
        gender: string;
        medical_history: Prisma.JsonValue;
        drug_allergy: Prisma.JsonValue;
        emergency_contact: Prisma.JsonValue;
        photo_url: string | null;
        role: import(".prisma/client").$Enums.Role;
        created_at: Date;
    }>;
}
