import { UsersService } from './users.service';
import { Prisma } from '@prisma/client';
export declare class UsersController {
    private readonly usersService;
    constructor(usersService: UsersService);
    findOne(id: string): Promise<{
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
    } | null>;
    update(id: string, data: Prisma.UserUpdateInput): Promise<{
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
