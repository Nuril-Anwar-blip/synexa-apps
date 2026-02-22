import { ChatService } from './chat.service';
export declare class ChatController {
    private readonly chatService;
    constructor(chatService: ChatService);
    getMessages(roomId: string): Promise<({
        sender: {
            full_name: string;
            photo_url: string | null;
        };
    } & {
        id: string;
        created_at: Date;
        content: string;
        metadata: import("@prisma/client/runtime/library").JsonValue | null;
        room_id: string;
        sender_id: string;
    })[]>;
    getRooms(userId: string): Promise<({
        pharmacist: {
            full_name: string;
            photo_url: string | null;
        };
        patient: {
            full_name: string;
            photo_url: string | null;
        };
    } & {
        id: string;
        created_at: Date;
        pharmacist_id: string;
        patient_id: string;
    })[]>;
}
