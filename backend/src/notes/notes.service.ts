import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Note } from './note.entity';
import { CreateNoteDto, UpdateNoteDto } from './note.dto';

@Injectable()
export class NotesService {
  constructor(
    @InjectRepository(Note)
    private notesRepository: Repository<Note>,
  ) {}

  async create(createNoteDto: CreateNoteDto): Promise<Note> {
    const note = this.notesRepository.create(createNoteDto);
    return await this.notesRepository.save(note);
  }

  async findAll(): Promise<Note[]> {
    return await this.notesRepository.find({
      order: {
        isPinned: 'DESC',
        updatedAt: 'DESC',
      },
    });
  }

  async findOne(id: string): Promise<Note> {
    const note = await this.notesRepository.findOne({ where: { id } });
    if (!note) {
      throw new NotFoundException(`Note with ID ${id} not found`);
    }
    return note;
  }

  async update(id: string, updateNoteDto: UpdateNoteDto): Promise<Note> {
    const note = await this.findOne(id);
    Object.assign(note, updateNoteDto);
    return await this.notesRepository.save(note);
  }

  async togglePin(id: string): Promise<Note> {
    const note = await this.findOne(id);
    note.isPinned = !note.isPinned;
    return await this.notesRepository.save(note);
  }

  async remove(id: string): Promise<void> {
    const note = await this.findOne(id);
    await this.notesRepository.remove(note);
  }

  async searchNotes(query: string): Promise<Note[]> {
    return await this.notesRepository
      .createQueryBuilder('note')
      .where('note.title ILIKE :query OR note.content ILIKE :query', {
        query: `%${query}%`,
      })
      .orderBy('note.isPinned', 'DESC')
      .addOrderBy('note.updatedAt', 'DESC')
      .getMany();
  }

  async findByCategory(category: string): Promise<Note[]> {
    return await this.notesRepository.find({
      where: { category },
      order: {
        isPinned: 'DESC',
        updatedAt: 'DESC',
      },
    });
  }
}
