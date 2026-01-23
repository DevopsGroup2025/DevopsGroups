import { Controller, Get, Post, Put, Delete, Body, Param, Query, HttpCode, HttpStatus } from '@nestjs/common';
import { NotesService } from './notes.service';
import { CreateNoteDto, UpdateNoteDto } from './note.dto';
import { Note } from './note.entity';

@Controller('api/notes')
export class NotesController {
  constructor(private readonly notesService: NotesService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() createNoteDto: CreateNoteDto): Promise<Note> {
    return await this.notesService.create(createNoteDto);
  }

  @Get()
  async findAll(@Query('search') search?: string, @Query('category') category?: string): Promise<Note[]> {
    if (search) {
      return await this.notesService.searchNotes(search);
    }
    if (category) {
      return await this.notesService.findByCategory(category);
    }
    return await this.notesService.findAll();
  }

  @Get(':id')
  async findOne(@Param('id') id: string): Promise<Note> {
    return await this.notesService.findOne(id);
  }

  @Put(':id')
  async update(@Param('id') id: string, @Body() updateNoteDto: UpdateNoteDto): Promise<Note> {
    return await this.notesService.update(id, updateNoteDto);
  }

  @Put(':id/pin')
  async togglePin(@Param('id') id: string): Promise<Note> {
    return await this.notesService.togglePin(id);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@Param('id') id: string): Promise<void> {
    await this.notesService.remove(id);
  }
}
