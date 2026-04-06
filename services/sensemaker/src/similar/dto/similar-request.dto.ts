import { IsOptional, IsString, MinLength, ValidateIf } from 'class-validator';
import type { SimilarRequest } from '@news-lab/types';

export class SimilarRequestDto implements SimilarRequest {
  @IsOptional()
  @IsString()
  articleId?: string;

  @ValidateIf((o: SimilarRequestDto) => !o.articleId)
  @IsString()
  @MinLength(20, { message: 'text must be at least 20 characters when articleId is not provided' })
  text?: string;
}
