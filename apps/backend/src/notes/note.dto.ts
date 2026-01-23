export class CreateNoteDto {
  title: string;
  content: string;
  category?: string;
  isPinned?: boolean;
}

export class UpdateNoteDto {
  title?: string;
  content?: string;
  category?: string;
  isPinned?: boolean;
}
