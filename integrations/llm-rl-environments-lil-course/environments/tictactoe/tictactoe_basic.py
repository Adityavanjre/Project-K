"""
BASIC TIC TAC TOE ENVIRONMENT

A basic Tic Tac Toe environment implementation for learning purposes.
A better implementation can be found in tictactoe.py.

Assumptions:
- The model always plays as X and starts first
- The opponent plays randomly
- Invalid moves currently result in an immediate loss for the model
"""

import random
from typing import Any

import verifiers as vf
from datasets import Dataset
from verifiers.types import Messages, State


# GAME LOGIC

WINNING_LINES = [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],  # rows
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],  # columns
    [0, 4, 8],
    [2, 4, 6],  # diagonals
]


def render_board(board: list[str | None]) -> str:
    """Render the board as a string with position numbers for empty cells."""

    def cell(i: int) -> str:
        return board[i] or str(i)

    return (
        f"{cell(0)} | {cell(1)} | {cell(2)}\n"
        f"---------\n"
        f"{cell(3)} | {cell(4)} | {cell(5)}\n"
        f"---------\n"
        f"{cell(6)} | {cell(7)} | {cell(8)}"
    )


def check_win(board: list[str | None], player: str) -> bool:
    """Check if the given player has won."""
    return any(all(board[i] == player for i in line) for line in WINNING_LINES)


def get_free_positions(board: list[str | None]) -> list[int]:
    """Get list of empty positions on the board."""
    return [i for i in range(9) if board[i] is None]


def get_random_move(board: list[str | None]) -> int:
    """Pick a random free position."""
    free = get_free_positions(board=board)
    return random.choice(free)


# VERIFIERS ENVIRONMENT

SYSTEM_PROMPT = f"""You are playing a game of Tic-Tac-Toe as X.
Your opponent will play as O.

Initial board:
{render_board([None] * 9)}

Your objective is to achieve three X in a row (horizontally, vertically, or diagonally) before the opponent does.
You can only choose one position each turn, and it must be an empty square.

Your final answer must include the position you choose inside <move>...</move> tags.
"""


def user_feedback(
    status: str, board: list[str | None], final: bool = False, as_messages: bool = True
) -> str | list[dict[str, str]]:
    """Format consistent feedback to the model."""
    content = f"{status}\n\n{render_board(board=board)}"

    if not final:
        free = get_free_positions(board=board)
        content += f"\n\nAvailable positions: {free}\n\nYour turn."

    if as_messages:
        return [{"role": "user", "content": content}]
    return content


class TicTacToeEnv(vf.MultiTurnEnv):
    async def setup_state(self, state: State) -> State:
        state["board"] = [None] * 9
        state["winner"] = None  # None=in progress, "X"/"O"=winner, "draw"=draw
        return state

    async def env_response(
        self, messages: Messages, state: State, **kwargs
    ) -> Messages:
        """Process model's move and opponent's response."""
        board = state["board"]
        move = self.parser.parse_answer(messages) or ""
        free = get_free_positions(board)

        # Validate move: must be one of the free positions
        if move not in [str(p) for p in free]:
            state["winner"] = "O"
            final = user_feedback(
                "Game over! Invalid move. You lose.", board, final=True
            )
            state["final_env_response"] = final
            return final

        pos = int(move)

        # Apply model's move (X) and check for win
        board[pos] = "X"
        if check_win(board=board, player="X"):
            state["winner"] = "X"
            final = user_feedback("Game over! You won!", board, final=True)
            state["final_env_response"] = final
            return final
        if not get_free_positions(board=board):
            state["winner"] = "draw"
            final = user_feedback("Game over! It's a draw.", board, final=True)
            state["final_env_response"] = final
            return final

        # Opponent's move (O) - always random
        opp_pos = get_random_move(board=board)
        board[opp_pos] = "O"
        opp_status = f"Opponent (O) played at position {opp_pos}."

        if check_win(board=board, player="O"):
            state["winner"] = "O"
            final = user_feedback(
                f"Game over! {opp_status} You lose.", board, final=True
            )
            state["final_env_response"] = final
            return final
        if not get_free_positions(board=board):
            state["winner"] = "draw"
            final = user_feedback(
                f"Game over! {opp_status} It's a draw.", board, final=True
            )
            state["final_env_response"] = final
            return final

        # Game continues
        return user_feedback(opp_status, board)


def win_reward_func(state: State, **kwargs: Any) -> float:
    winner = state.get("winner")
    return 1.0 if winner == "X" else 0.5 if winner == "draw" else 0.0


def load_environment(
    num_examples: int = 100,
    **kwargs,
) -> vf.Environment:
    # Create dataset - model always starts
    def make_dataset():
        rows = []
        for _ in range(num_examples):
            rows.append(
                {
                    "question": user_feedback(
                        "Game started. You are X.", [None] * 9, as_messages=False
                    ),
                }
            )
        return Dataset.from_list(rows)

    parser = vf.XMLParser(fields=["move"], answer_field="move")
    rubric = vf.Rubric(parser=parser, funcs=[win_reward_func])
    rubric.add_reward_func(parser.get_format_reward_func(), weight=0.2)

    return TicTacToeEnv(
        dataset=make_dataset(),
        system_prompt=SYSTEM_PROMPT,
        parser=parser,
        rubric=rubric,
        max_turns=10,
        **kwargs,
    )
