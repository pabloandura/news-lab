import { IsNotEmpty, IsString, MaxLength, MinLength } from 'class-validator';
import { FactCheckRequest } from '@news-lab/types';

export class FactCheckRequestDto implements FactCheckRequest {
  @IsString()
  @IsNotEmpty()
  articleId!: string;

  @IsString()
  @MinLength(50, { message: 'text must be at least 50 characters to analyse' })
  @MaxLength(50_000)
  text!: string;
}
