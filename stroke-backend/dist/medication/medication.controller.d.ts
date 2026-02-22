import { MedicationService } from './medication.service';
import { Prisma } from '@prisma/client';
export declare class MedicationController {
    private readonly medicationService;
    constructor(medicationService: MedicationService);
    findAllByUser(userId: string): Promise<{
        name: string;
        id: string;
        created_at: Date;
        user_id: string;
        dose: string | null;
        note: string | null;
        time: Date;
        period: import(".prisma/client").$Enums.Period;
        taken: boolean;
        updated_at: Date;
        is_active: boolean;
        current_stock: number;
        total_stock: number;
    }[]>;
    create(data: Prisma.MedicationReminderCreateInput): Promise<{
        name: string;
        id: string;
        created_at: Date;
        user_id: string;
        dose: string | null;
        note: string | null;
        time: Date;
        period: import(".prisma/client").$Enums.Period;
        taken: boolean;
        updated_at: Date;
        is_active: boolean;
        current_stock: number;
        total_stock: number;
    }>;
    markAsTaken(id: string): Promise<{
        name: string;
        id: string;
        created_at: Date;
        user_id: string;
        dose: string | null;
        note: string | null;
        time: Date;
        period: import(".prisma/client").$Enums.Period;
        taken: boolean;
        updated_at: Date;
        is_active: boolean;
        current_stock: number;
        total_stock: number;
    }>;
    updateStock(id: string, amount: number): Promise<{
        name: string;
        id: string;
        created_at: Date;
        user_id: string;
        dose: string | null;
        note: string | null;
        time: Date;
        period: import(".prisma/client").$Enums.Period;
        taken: boolean;
        updated_at: Date;
        is_active: boolean;
        current_stock: number;
        total_stock: number;
    }>;
}
