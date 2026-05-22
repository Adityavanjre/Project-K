import { NextRequest, NextResponse } from 'next/server';
import { listSkills, writeSkill } from '@/services/skills/skillService';

export const runtime = 'nodejs';

export async function GET() {
  try {
    const skills = listSkills();
    return NextResponse.json({ success: true, data: skills });
  } catch (error) {
    console.error('[API /skills] error:', error);
    return NextResponse.json(
      { success: false, error: error instanceof Error ? error.message : 'Failed to list skills' },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const name = typeof body?.name === 'string' ? body.name.trim() : '';
    const content = typeof body?.content === 'string' ? body.content : '';

    if (!name) {
      return NextResponse.json(
        { success: false, error: 'Skill name is required' },
        { status: 400 }
      );
    }

    if (!content.trim()) {
      return NextResponse.json(
        { success: false, error: 'Skill content is required' },
        { status: 400 }
      );
    }

    const result = writeSkill(name, content);
    if (!result.success) {
      return NextResponse.json(
        { success: false, error: result.error || 'Failed to write skill' },
        { status: 400 }
      );
    }

    return NextResponse.json({
      success: true,
      message: `Skill "${name}" saved`,
    });
  } catch (error) {
    console.error('[API /skills POST] error:', error);
    return NextResponse.json(
      { success: false, error: error instanceof Error ? error.message : 'Failed to write skill' },
      { status: 500 }
    );
  }
}
