import { NextRequest, NextResponse } from 'next/server';
import { readSkill, deleteSkill } from '@/services/skills/skillService';

export const runtime = 'nodejs';

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ name: string }> }
) {
  try {
    const { name } = await params;
    const skill = readSkill(name);
    if (!skill) {
      return NextResponse.json(
        { success: false, error: `Skill "${name}" not found` },
        { status: 404 }
      );
    }

    return NextResponse.json({ success: true, data: skill });
  } catch (error) {
    console.error('[API /skills/[name]] error:', error);
    return NextResponse.json(
      { success: false, error: error instanceof Error ? error.message : 'Failed to read skill' },
      { status: 500 }
    );
  }
}

export async function DELETE(
  _request: NextRequest,
  { params }: { params: Promise<{ name: string }> }
) {
  try {
    const { name } = await params;
    const result = deleteSkill(name);
    if (!result.success) {
      return NextResponse.json(
        { success: false, error: result.error },
        { status: 400 }
      );
    }

    return NextResponse.json({ success: true, message: `Skill "${name}" deleted` });
  } catch (error) {
    console.error('[API /skills/[name] DELETE] error:', error);
    return NextResponse.json(
      { success: false, error: error instanceof Error ? error.message : 'Failed to delete skill' },
      { status: 500 }
    );
  }
}
