# Dots and Boxes — Game Rules

Slug: `dotsandboxes`

## 1. Objective

Two to four players take turns drawing edges between adjacent dots on a
rectangular grid.
Each time a player completes the fourth side of a 1×1 box, they claim that box,
mark it with their color, and take another turn. When every possible box is
claimed, the player who claimed the most boxes wins.

## 2. Setup

- The board is a grid of **D × D dots** (default 6×6 dots → 5×5 boxes).
  Supported sizes: 5×5, 6×6, 7×7 dots.
- **Box count (authoritative):** a D×D dot grid always contains exactly
  (D−1)² boxes — 16 on 5×5 dots, 25 on 6×6 dots, 36 on 7×7 dots. No other
  counting is used anywhere in the rules or the app; every total, score
  sum and tie check is derived from this formula.
- Two to four players (seats). Each seat is a human (pass-and-play) or the
  Robot; at least one seat must be human. In a 2-seat game the seats are
  Player 1 ("You", cherry red) and Player 2 ("Robot" or a second human,
  sky blue); seats 3 and 4 use leaf green and honey amber.
- The board starts completely empty — no edges drawn, no boxes claimed.
- Seat 1 always moves first.
- Score starts at 0 for every seat.

## 3. Turn order

- Seats take turns in seat order, one edge per turn.
- **Exception (bonus turn):** if a move completes one or more boxes, the player
  who completed them claims ALL of those boxes and immediately takes another
  turn (they do not pass the turn).
- Consecutive bonus turns continue until the player makes a move that completes
  no box, at which point the turn passes to the next seat.

## 4. Legal moves

- Draw exactly one horizontal or vertical edge between two **orthogonally
  adjacent** dots (one unit apart).
- The edge must connect two dots that share a grid line — either side by side
  in the same row, or one directly above the other in the same column.
- The edge must not already exist (no duplicate edges).
- The edge may complete 0, 1, or 2 boxes (an interior edge can complete two
  adjacent boxes at once; a border edge can complete at most one).
- A move is legal even if it gives the opponent an immediate box — legality
  only requires the edge be new and connect adjacent dots.

## 5. Illegal moves

- Connecting two dots that are **not adjacent** (distance > 1 unit).
- Drawing a **diagonal** edge between dots.
- Re-drawing an edge that has already been claimed.
- Drawing an edge outside the grid boundaries.
- Passing the turn without drawing an edge (a player may not skip).
- Drawing more than one edge in a single turn.
- Moving out of turn (except on a bonus turn earned by completing a box).

## 6. Captures

- "Capture" in Dots and Boxes means claiming a box: the moment the fourth side
  of a 1×1 box is drawn, that box is captured by the player who drew it.
- A captured box is permanently marked with the capturing player's color
  (plus their initial/star token) and can never change ownership.
- Capturing a box grants an immediate bonus turn (see §3).
- A single edge can capture two boxes at once if it is the shared fourth side
  of two adjacent boxes — both are claimed by the same player, who still gets
  only one bonus turn (not two).

## 7. Special rules

- **Chain rule (sacrifice):** when a player is forced to give away boxes, the
  standard expert play is to take all but 2 boxes of a chain and sacrifice the
  last 2 to the opponent ("loony move" control). This is strategy, not a rule
  change — the rules simply award every completed box to whoever draws its
  fourth side.
- **No passing:** a player who has a legal edge must draw one.
- **Last move:** the player who draws the final edge of the game claims any
  boxes it completes, takes their bonus turn, and then the game ends because
  no edges remain (the bonus turn is moot).
- **Simultaneous completion:** if one edge completes two boxes, both belong to
  the mover; there is no tie-break.

## 8. Scoring

- Each claimed box = 1 point.
- The scoreboard shows each player's box count as a running total.
- Total boxes on a D×D dot grid = (D−1)² exactly (e.g., 16 on 5×5 dots,
  25 on 6×6, 36 on 7×7). All seats' scores always sum to the total box count.
- There is no partial credit, no combo multiplier — scoring is purely the
  count of claimed boxes.

## 9. Winning conditions

- When all boxes are claimed, the seat with the **highest box count** wins.
- The winner is announced immediately ("Red Wins!" / "You Win!" / the
  winner's name).
- Margin of victory is the difference between the winner's count and the
  runner-up's count.

## 10. Draw conditions

- A draw is declared when two or more seats tie for the highest box count.
- With 2 seats a tie requires the total box count to be even: 5×5 dots →
  16 boxes allows an 8–8 draw; 7×7 dots → 36 boxes allows an 18–18 draw.
  On the default 6×6 dot board (25 boxes, odd) a 2-seat draw is
  mathematically impossible.
- With 3–4 seats a top-score tie is possible on any board size.
- On a draw the result is announced as "It's a Tie!" — no tie-break is played.

## 11. AI strategy

Difficulty levels for the Robot opponent:

- **Easy:** picks a uniformly random legal edge. Does not avoid giving away
  boxes.
- **Medium:** greedy — (1) if any edge completes a box, take the one completing
  the most boxes (2 if possible); (2) otherwise, play a "safe" edge that does
  not create a box with 3 sides for the opponent, chosen randomly among safe
  edges; (3) if no safe edge exists, play the edge that gives away the fewest
  boxes (shortest chain sacrifice), preferring to sacrifice only 2 boxes.
- **Hard:** Medium's rules plus 2-ply lookahead: after its move, it evaluates
  the opponent's best greedy reply and avoids moves whose reply nets the
  opponent more boxes than an alternative; on forced sacrifices it applies the
  chain rule (keeps all but 2 of the chain). Depth-limited minimax over box
  differential is acceptable on 5×5; on larger boards use the heuristic above
  to stay within a 1-second move budget.

## 12. Edge cases

- Drawing the last edge of the game when it completes no box: turn would pass,
  but the game ends immediately — no further moves exist.
- Bonus turn with no remaining edges: game ends; the bonus is not taken.
- An edge completing 2 boxes on the final move: both boxes are claimed, then
  the game ends.
- Undo: removes the most recent edge (and un-claims any boxes it completed,
  restoring the turn to the player who drew it). In games with robot seats,
  undo unwinds moves until it is a human seat's turn again. Undo is disabled
  while a robot is thinking or any animation is playing.
- Board size change mid-game: not allowed — changing size starts a new game.
- Attempting to draw on an already-drawn edge: rejected with a gentle shake
  animation and a "That line is already drawn!" hint; no turn is consumed.
- Bot seats never move silently: every robot line is drawn with a visible
  stroke animation and every claimed box pops in one by one, with narration
  on the active seat's tray.

## 13. Test cases

1. **First move legality:** on a fresh 6×6 board, Player 1 draws any single
   adjacent edge → accepted, score stays 0–0, turn passes to Player 2.
2. **Diagonal rejected:** attempt an edge between (0,0) and (1,1) → rejected,
   no state change, turn not consumed.
3. **Duplicate rejected:** draw edge (0,0)–(0,1), then attempt the same edge →
   rejected, turn not consumed.
4. **Non-adjacent rejected:** attempt (0,0)–(0,2) → rejected.
5. **Single box capture:** with three sides of box (0,0) drawn, the player who
   draws the fourth side → box claimed in their color, score +1, same player
   moves again.
6. **Double box capture:** on the shared edge between two boxes that both have
   their other three sides drawn, drawing that edge → both boxes claimed by
   the mover, score +2, one bonus turn.
7. **Bonus turn chain:** player completes a box, then completes another box on
   the bonus move → claims both, keeps the turn again.
8. **Full game 5×5:** play a complete game to the last edge → final scores sum
   to 16, winner = higher count, game-over screen shows.
9. **Draw detection:** on a 7×7 dot board, a scripted game ending 18–18 →
   result announced as tie.
10. **No-draw on odd boards:** the default 6×6 dot game can never end tied
   (25 is odd) — verify winner is always declared.
11. **Robot Medium takes free box:** set up a box with 3 sides before the
    robot's turn → robot draws the fourth side and claims it.
12. **Robot Medium avoids 3rd side:** with no capturable box, robot's move must
    not create any box with exactly 3 sides when a safe edge exists.
13. **Undo after capture:** player captures a box, presses Undo → box un-claimed,
    edge removed, score reverted, same player's turn restored.
14. **Out-of-bounds:** attempt an edge with a dot coordinate outside the grid →
    rejected.
15. **Last-move capture:** the final edge of the game completes a box → box
    claimed, scores final, game ends without an extra turn prompt.
16. **Box count exactness:** 5×5 dots → exactly 16 boxes, 6×6 dots → exactly
    25, 7×7 dots → exactly 36; a scripted full game on each size ends with
    scores summing to the exact total.
17. **Four-seat game:** a scripted 4-seat game completes with all seats'
    scores summing to the total box count and a single winner (or a declared
    top-score tie) announced.
