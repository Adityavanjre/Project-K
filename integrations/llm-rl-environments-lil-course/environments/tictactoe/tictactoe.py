import random
import re
from functools import lru_cache
from typing import Any, Sequence

from datasets import Dataset
from verifiers.types import Messages, State

import verifiers as vf


# --- GAME LOGIC ---

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


def check_win(board: Sequence[str | None], player: str) -> bool:
    """Check if the given player has won."""
    return any(all(board[i] == player for i in line) for line in WINNING_LINES)


def get_free_positions(board: Sequence[str | None]) -> list[int]:
    """Get list of empty positions on the board."""
    return [i for i in range(9) if board[i] is None]


@lru_cache(maxsize=None)
def minimax(
    board: tuple[str | None, ...], is_maximizing: bool
) -> tuple[float, list[int]]:
    """Minimax that returns score and best moves, favoring efficiency.

    Wins with more free squares (faster) are worth more.
    Losses with fewer free squares (prolonged) are less negative.
    """
    free = get_free_positions(board)

    if check_win(board, "O"):
        # Winning earlier (more free squares) is better
        return 1.0 + len(free), []
    if check_win(board, "X"):
        # Losing later (fewer free squares) is better
        return -1.0 - len(free), []

    if not free:
        return 0.0, []

    player = "O" if is_maximizing else "X"

    # Evaluate all possible moves
    results = []
    for pos in free:
        board_list = list(board)
        board_list[pos] = player
        score, _ = minimax(tuple(board_list), not is_maximizing)
        results.append((score, pos))

    # Identify best score and all moves that reach it
    scores = [res[0] for res in results]
    best_score = max(scores) if is_maximizing else min(scores)
    best_moves = [pos for score, pos in results if score == best_score]

    return best_score, best_moves


def get_opponent_move(
    board: list[str | None], rng: random.Random, random_prob: float = 0.0
) -> int:
    """Pick opponent's move: random with probability random_prob, otherwise optimal."""
    if rng.random() < random_prob:
        return rng.choice(get_free_positions(board))
    _, best_moves = minimax(tuple(board), is_maximizing=True)
    assert best_moves
    return rng.choice(best_moves)


# --- VERIFIERS ENVIRONMENT ---

SYSTEM_PROMPT = f"""You are playing a game of Tic-Tac-Toe as X.
Your opponent will play as O.

Initial board:
{render_board([None] * 9)}

Your objective is to achieve three X in a row (horizontally, vertically, or diagonally) before the opponent does.
You can only choose one position each turn, and it must be an empty square.

You may include a short reasoning process inside <think>...</think> tags.
Your final answer must include the position you choose inside <move>...</move> tags.
"""


def user_feedback(
    status: str, board: list[str | None], final: bool = False, as_messages: bool = True
) -> str | list[dict[str, str]]:
    """Format feedback to the model."""
    content = f"{status}\n\n{render_board(board)}"

    if not final:
        free = get_free_positions(board)
        content += f"\n\nAvailable positions: {free}\n\nYour turn."

    if as_messages:
        return [{"role": "user", "content": content}]
    return content


class TicTacToeEnv(vf.MultiTurnEnv):
    async def setup_state(self, state: State) -> State:
        info = state.get("info", {})
        state["board"] = list(info.get("initial_board"))
        state["winner"] = None
        state["random_move_prob"] = info.get("random_move_prob", 0.0)
        state["example_seed"] = info.get("example_seed", 42)
        state["invalid_moves"] = 0
        return state

    async def env_response(
        self, messages: Messages, state: State, **kwargs
    ) -> Messages:
        """Process the model's move and return environment feedback."""
        board = state["board"]
        move = self.parser.parse_answer(messages) or ""
        free = get_free_positions(board)

        # Validate move format
        if not move:
            state["invalid_moves"] += 1
            return user_feedback(
                "Please provide a move inside <move>...</move> tags.", board
            )

        # Validate move is a free position
        if move not in [str(p) for p in free]:
            state["invalid_moves"] += 1
            return user_feedback("Invalid move.", board, as_messages=True)

        pos = int(move)

        # Apply model's move (X) and check for win
        board[pos] = "X"
        if check_win(board, "X"):
            state["winner"] = "X"
            final = user_feedback("You win!", board, final=True, as_messages=True)
            state["final_env_response"] = final
            return final
        if not get_free_positions(board):
            state["winner"] = "draw"
            final = user_feedback("It's a draw!", board, final=True, as_messages=True)
            state["final_env_response"] = final
            return final

        # Opponent's move (O)
        turn_seed = f"{state['example_seed']}_{state['board']}"
        rng = random.Random(turn_seed)
        opp_pos = get_opponent_move(board, rng, state["random_move_prob"])

        # Apply opponent's move (O) and check for win
        board[opp_pos] = "O"
        opp_status = f"Opponent (O) played at position {opp_pos}."
        if check_win(board, "O"):
            state["winner"] = "O"
            final = user_feedback(
                f"{opp_status} You lose!", board, final=True, as_messages=True
            )
            state["final_env_response"] = final
            return final
        if not get_free_positions(board):
            state["winner"] = "draw"
            final = user_feedback(
                f"{opp_status} It's a draw!", board, final=True, as_messages=True
            )
            state["final_env_response"] = final
            return final

        # Game continues
        return user_feedback(opp_status, board, as_messages=True)


def win_reward_func(state: State, **kwargs: Any) -> float:
    """Reward function: 1.0 for win, 0.5 for draw, 0.0 for loss/timeout."""
    winner = state.get("winner")
    if winner is None:
        return 0.0
    return 1.0 if winner == "X" else 0.5 if winner == "draw" else 0.0


def invalid_move_penalty_func(state: State, **kwargs: Any) -> float:
    """Flat penalty if any invalid move occurred."""
    return -0.1 if state.get("invalid_moves", 0) > 0 else 0.0


def load_environment(
    num_examples: int = 1000,
    min_random_move_prob: float = 0.0,
    max_random_move_prob: float = 1.0,
    max_turns: int = 8,
    num_groups: int = 1,
    **kwargs,
) -> vf.Environment:
    # Stratified sampling: Ensures every batch covers the full spectrum of difficulties.
    # For training, num_groups should be equal to batch_size // rollouts_per_example.
    difficulty_step = (max_random_move_prob - min_random_move_prob) / num_groups

    def make_dataset():
        rows = []
        for i in range(num_examples):
            board: list[str | None] = [None] * 9

            bucket_index = i % num_groups
            interval_start = min_random_move_prob + (bucket_index * difficulty_step)
            random_move_prob = interval_start + random.uniform(0, difficulty_step)

            example_seed = random.randint(0, 1000000)

            rng = random.Random(f"{example_seed}_{board}")

            if rng.random() < 0.5:
                # Model starts
                question = user_feedback(
                    "Game started. You are X.", board, as_messages=False
                )
            else:
                # Opponent starts
                opp_pos = get_opponent_move(board, rng, random_move_prob)

                board[opp_pos] = "O"
                question = user_feedback(
                    f"Game started. Opponent (O) played at position {opp_pos}.",
                    board,
                    as_messages=False,
                )

            rows.append(
                {
                    "question": question,
                    "info": {
                        "initial_board": board,
                        "random_move_prob": random_move_prob,
                        "example_seed": example_seed,
                    },
                }
            )
        return Dataset.from_list(rows)

    # Simple parser: just extract <move> tag
    parser = vf.XMLParser(fields=["move"], answer_field="move")

    # Format reward: requires <think>...</think><move>...</move> structure when use_think=True
    format_pattern = re.compile(
        r"<think>.*?</think>.*?<move>.*?</move>",
        re.DOTALL,
    )

    def format_reward_func(parser, completion, **kwargs) -> float:
        assistant_msgs = parser.get_assistant_messages(completion)
        if not assistant_msgs:
            return 0.0
        scores = [
            1.0 if format_pattern.search(msg.get("content", "")) else 0.0
            for msg in assistant_msgs
        ]
        return sum(scores) / len(scores)

    rubric = vf.Rubric(
        parser=parser,
        funcs=[
            win_reward_func,
            format_reward_func,
            invalid_move_penalty_func,
        ],
        weights=[1.0, 0.2, 1.0],
    )

    return TicTacToeEnv(
        dataset=make_dataset(),
        system_prompt=SYSTEM_PROMPT,
        parser=parser,
        rubric=rubric,
        max_turns=max_turns,
        **kwargs,
    )
