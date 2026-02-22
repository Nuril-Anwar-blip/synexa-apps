import { PrismaService } from '../prisma/prisma.service';
import { MedicationReminder, Prisma } from '@prisma/client';
export declare class MedicationService {
    private prisma;
    constructor(prisma: PrismaService);
    findAllByUser(userId: string): Promise<MedicationReminder[]>;
    create(data: Prisma.MedicationReminderCreateInput): Promise<MedicationReminder>;
    markAsTaken(id: string): Promise<MedicationReminder>;
    updateStock(id: string, amount: number): Promise<MedicationReminder>;
}
