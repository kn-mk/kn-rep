PFont jpFont;
//HashSetのインポート
import java.util.Set;
import java.util.HashSet;
int[] scores = new int[4]; // プレイヤー最大4人ぶんのスコア
int turnCount = 0;

//制限時間ペナルティ↓
//int turnStartTime; // ミリ秒単位のターン開始時刻
//int timeLimitSeconds = 20; // 1ターンの制限秒数（変更可能）
//int timePenaltyInterval = 20; // 何秒ごとに-1ptされるか（初期は20秒）

int turnStartTime = 0;  // 毎ターンの開始時間（millis）
int timePenaltyInterval = 20000; // 20秒（ミリ秒単位）←後で変更しやすく
int penaltyCount = 0;//20sごとに行うため、前回の減点回数を記録する
//制限時間ペナルティ↑
int fullTurnCount = 1;//ターン数カウント
int maxTurns = 3;
String gameOverReason = "";
boolean isGameOver = false;
int maxTurnLimit = 20;  // 初期値。あとで設定画面から変更される

//再指摘防止↓
HashSet<Set<Pawn>> accusedHistory = new HashSet<Set<Pawn>>();
//↓同一円周上かどうかのやつ

boolean isAccusing = false; // 指摘モードかどうか

ArrayList<Pawn> accusedPawns = new ArrayList<Pawn>(); // 選択された敵駒たち
//↑同一円周上かどうかのやつ

//タイトル画面↓
enum GameState { TITLE, PLAYING, GAMEOVER }
GameState currentState = GameState.TITLE;
enum TitleState {
  SELECT_PLAYERS,
  SELECT_TURNS,
  SELECT_TIME,
  READY_TO_START
}
TitleState titleState = TitleState.SELECT_PLAYERS;

int[] possibleTurns = {6,10, 15, 20, 30, 50, 999};
int turnIndex = 0;
int selectedMaxTurns = possibleTurns[turnIndex];

int[] possibleTimeLimits = {10, 15, 20, 30, 60};
int timeIndex = 1;
int selectedTimeLimit = possibleTimeLimits[timeIndex];


int selectedPlayers = 2;
//int selectedMaxTurns = 30; // -1で無制限
//int selectedTimeLimit = 20;

String[] playerOptions = { "2人", "3人", "4人" };
String[] turnOptions = { "15", "30", "50", "無制限" };
String[] timeOptions = { "10秒", "20秒", "30秒" };
//タイトル画面↑

void setup() {
  size(1920, 1080);
  jpFont = loadFont("Meiryo-32.vlw");  // 作成したフォント名に合わせて
  textFont(jpFont);  
  background(0,0,100,100);
  colorMode(HSB, 360, 100, 100, 100);
  currentState = GameState.TITLE;//タイトル画面
  //指定した後の再指摘を防ぐ
  ArrayList<Pawn> accusedHistory = new ArrayList<Pawn>();

  if (totalPlayers == 2) {
    // プレイヤー0: 上段中央8個
    for (int i = 1; i <= 8; i++) {
      pawns.add(new Pawn(i, 0, 0));
    }
    // プレイヤー1: 下段中央8個
    for (int i = 1; i <= 8; i++) {
      pawns.add(new Pawn(i, 9, 1));
    }
  } else if (totalPlayers == 3 || totalPlayers == 4) {
    // プレイヤー0: 上段中央8個
    for (int i = 1; i <= 8; i++) {
      pawns.add(new Pawn(i, 0, 0));
    }
    // プレイヤー1: 下段中央8個
    for (int i = 1; i <= 8; i++) {
      pawns.add(new Pawn(i, 9, 1));
    }
    // プレイヤー2: 左側中央8個（縦に並べる）
    if (totalPlayers >= 3) {
      for (int i = 1; i <= 8; i++) {
        pawns.add(new Pawn(0, i, 2));
      }
    }
    // プレイヤー3: 右側中央8個（縦に並べる）
    if (totalPlayers == 4) {
      for (int i = 1; i <= 8; i++) {
        pawns.add(new Pawn(9, i, 3));
      }
    }
  }
}

//タイトル画面↓
/*
void drawTitleScreen() {
  background(220);
  textAlign(CENTER, CENTER);
  textSize(120);
  text("ゲームタイトル", width/2, height/4);
  
  textSize(30);
  text("プレイヤー人数：" + playerOptions[selectedPlayers - 2], width/2 , 450);
  text("最大ターン数：" + (selectedMaxTurns == -1 ? "無制限" : selectedMaxTurns), width/2, 500);
  text("制限時間：" + selectedTimeLimit + "秒", width/2, 550);

  text("クリックで設定を変更", width/2, 650);
  text("Sキーでゲーム開始", width/2, 700);
}
*/
void drawTitleScreen() {
  background(320);
  fill(0);
  textAlign(CENTER, CENTER);
  textFont(jpFont);
  textSize(120);
  text("ハサミ将棋  ×   共円      ", width / 2, height / 6+100);

  textSize(40);
  float y = height / 2 - 60;
  
  fill(titleState == TitleState.SELECT_PLAYERS ? color(234, 87, 98) : 0);
  text("プレイヤー人数: " + selectedPlayers, width / 2, y);

  y += 60;
  fill(titleState == TitleState.SELECT_TURNS ? color(234, 87, 98) : 0);
  String turnText = selectedMaxTurns == 999 ? "無制限" : selectedMaxTurns + " ターン";
  text("最大ターン数: " + turnText, width / 2, y);

  y += 60;
  fill(titleState == TitleState.SELECT_TIME ? color(234, 87, 98) : 0);
  text("制限時間: " + selectedTimeLimit + " 秒", width / 2, y);

  y += 80;
  fill(0);
  if (titleState == TitleState.READY_TO_START) {
    text("ENTERでスタート！", width / 2, y);
  } else {
    text("← → で変更 / ENTERで決定", width / 2, y);
  }
}


void setupGame() {
  pawns = new ArrayList<Pawn>();
  scores = new int[selectedPlayers];
  totalPlayers = selectedPlayers;
  accusedPawns.clear();
  accusedHistory.clear();
  penaltyCount = 0;
  turnStartTime = millis();
  currentPlayer = 0;
  fullTurnCount = 1;
  isAccusing = false;
  isGameOver = false;
  gameOverReason = "";

  if (totalPlayers == 2) {
    for (int i = 1; i <= 8; i++) pawns.add(new Pawn(i, 0, 0));
    for (int i = 1; i <= 8; i++) pawns.add(new Pawn(i, 9, 1));
  } else if (totalPlayers == 3 || totalPlayers == 4) {
    for (int i = 1; i <= 8; i++) pawns.add(new Pawn(i, 0, 0));
    for (int i = 1; i <= 8; i++) pawns.add(new Pawn(i, 9, 1));
    if (totalPlayers >= 3) {
      for (int i = 1; i <= 8; i++) pawns.add(new Pawn(0, i, 2));
    }
    if (totalPlayers == 4) {
      for (int i = 1; i <= 8; i++) pawns.add(new Pawn(9, i, 3));
    }
  }
}



/*
void draw() {
    if (isGameOver) {
      background(40); // 真っ黒背景
      fill(255);
      textAlign(CENTER, CENTER);
      if (jpFont != null) {
        textFont(jpFont);
      } else {
        textFont(createFont("Arial", 32)); // フォント読み込み失敗対策
      }
      textSize(130);
      text("Game Over", width / 2, height / 2 - 120);
      textSize(35);
      text(gameOverReason, width / 2, height / 2 - 20);
      textSize(40);
      text("Final Scores:", width / 2, height / 2 + 40);
    
      textSize(30);
      for (int i = 0; i < totalPlayers; i++) {
        text("Player " + (i + 1) + ": " + scores[i] + " pt", width / 2, height / 2 + 80 + i * 40);
      }
      return; // それ以外の描画をスキップ
    }
    colorMode(RGB,255);
    background(215);
    colorMode(HSB,360,100,100,100);
    drawBoard();
    drawPawns(); // 駒を描く
    drawScores();//スコアを表示
    // 指摘中なら赤枠を描く
    if (isAccusing) {
      stroke(255, 0, 0);
      strokeWeight(3);
      noFill();
      for (Pawn p : accusedPawns) {
        float px = BOARD_MARGIN + p.x * CELL_SIZE;
        float py = BOARD_MARGIN + p.y * CELL_SIZE;
        ellipse(px, py, CELL_SIZE * 0.6, CELL_SIZE * 0.6);
      }
      strokeWeight(1);
    }
    //制限時間ペナルティ↓
    int elapsed = millis() - turnStartTime;
    int elapsedSeconds = elapsed / 1000;
    int remaining = max(0, (timePenaltyInterval - (elapsed % timePenaltyInterval)) / 1000);

    fill(0);
    textFont(createFont("Arial Bold", 40)); // 太字フォントを使う
    textSize(115);
    textAlign(RIGHT, TOP);
    text("Time: " + nf(remaining, 2) + "s", width - 20, 20);
    textAlign(LEFT, TOP);
    fill(0);
    textSize(50);  // 見やすい大きさ
    text("Turn: " + fullTurnCount, 20, 20);

  // ペナルティ判定とスコア減点
    int penalty = elapsed / timePenaltyInterval;
    if (penalty > penaltyCount) {
      int diff = penalty - penaltyCount;
      scores[currentPlayer] = (scores[currentPlayer] - diff);
      penaltyCount = penalty;
    }
    //制限時間ペナルティ↑

    // ペナルティ表示
    textAlign(RIGHT, TOP);
    textSize(60);
    text("Penalty: -" + penalty + "pt", width -40, 150);
}
*/

void draw() {
  if (currentState == GameState.TITLE) {
    drawTitleScreen(); // タイトル画面の描画だけする
    return;
  }

  if (currentState == GameState.GAMEOVER || isGameOver) {
    background(40);
    fill(255);
    textAlign(CENTER, CENTER);
    if (jpFont != null) {
      textFont(jpFont);
    } else {
      textFont(createFont("Arial", 32));
    }
    textSize(130);
    text("Game Over", width / 2, height / 2 - 120);
    textSize(35);
    text(gameOverReason, width / 2, height / 2 - 20);
    textSize(40);
    text("Final Scores:", width / 2, height / 2 + 40);

    textSize(30);
    for (int i = 0; i < totalPlayers; i++) {
      text("Player " + (i + 1) + ": " + scores[i] + " pt", width / 2, height / 2 + 80 + i * 40);
    }
    return;
  }

  // 以下ゲームプレイ中の描画
  colorMode(RGB,255);
  background(215);
  colorMode(HSB,360,100,100,100);
  drawBoard();
  drawPawns();
  drawScores();

  if (isAccusing) {
    stroke(255, 0, 0);
    strokeWeight(3);
    noFill();
    for (Pawn p : accusedPawns) {
      float px = BOARD_MARGIN + p.x * CELL_SIZE;
      float py = BOARD_MARGIN + p.y * CELL_SIZE;
      ellipse(px, py, CELL_SIZE * 0.6, CELL_SIZE * 0.6);
    }
    strokeWeight(1);
  }

  // タイマー関連表示とペナルティ処理
  int elapsed = millis() - turnStartTime;
  int elapsedSeconds = elapsed / 1000;
  int remaining = max(0, (timePenaltyInterval - (elapsed % timePenaltyInterval)) / 1000);

  fill(0);
  textFont(createFont("Arial Bold", 40));
  textSize(115);
  textAlign(RIGHT, TOP);
  text("Time: " + nf(remaining, 2) + "s", width - 20, 20);
  textAlign(LEFT, TOP);
  textSize(50);
  text("Turn: " + fullTurnCount, 20, 20);

  int penalty = elapsed / timePenaltyInterval;
  if (penalty > penaltyCount) {
    int diff = penalty - penaltyCount;
    scores[currentPlayer] = (scores[currentPlayer] - diff);
    penaltyCount = penalty;
  }

  textAlign(RIGHT, TOP);
  textSize(60);
  text("Penalty: -" + penalty + "pt", width - 40, 150);
}

//currentPlayerを更新した後などに呼ぶ↓
void startTurn() {
  turnStartTime = millis();  // 現在時刻を記録
  penaltyCount = 0;
}

//final...変わったらまずいもの
final int BOARD_SIZE = 10;       // 盤のマス数を 8x8 に
final int CELL_SIZE = 100;      // 1マスあたりのピクセル数（正方形）
final int BOARD_MARGIN = 100;   // 画面の左・上の余白（見た目のため）

// 実際のピクセルサイズは 線の間が7つ（交点数に注意）
final int BOARD_PIXEL_SIZE = CELL_SIZE * (BOARD_SIZE - 1); 

void drawBoard() {
  stroke(0);         // 線の色：黒
  strokeWeight(2);   // 線の太さ

  // 縦線
  //繰り返し:for (初期化; 条件式; 更新)
  for (int i = 0; i < BOARD_SIZE; i++) {
    int x = BOARD_MARGIN + i * CELL_SIZE;
    int yStart = BOARD_MARGIN;
    int yEnd = BOARD_MARGIN + (BOARD_SIZE - 1) * CELL_SIZE;
    line(x, yStart, x, yEnd);
  }

  // 横線
  for (int j = 0; j < BOARD_SIZE; j++) {
    int y = BOARD_MARGIN + j * CELL_SIZE;
    int xStart = BOARD_MARGIN;
    int xEnd = BOARD_MARGIN + (BOARD_SIZE - 1) * CELL_SIZE;
    line(xStart, y, xEnd, y);
  }
}

//駒のデータ構造の定義
class Pawn {
  int x, y;     // グリッド座標（0～7）
  int owner;    // プレイヤー番号（0,1,2,...）

  // 🔽 これが必要なコンストラクタです
  Pawn(int x, int y, int owner) {
    this.x = x;
    this.y = y;
    this.owner = owner;
  }
  // 同じ座標＆同じ持ち主なら同一の駒とみなす
  public boolean equals(Object obj) {
    if (!(obj instanceof Pawn)) return false;
    Pawn other = (Pawn) obj;
    return this.x == other.x && this.y == other.y && this.owner == other.owner;
  }

  public int hashCode() {
    return x * 31 * 31 + y * 31 + owner;
  }
}

//これで複数の駒が記録できる↓
ArrayList<Pawn> pawns = new ArrayList<Pawn>();

//駒の定義↓
void drawPawns() {
  for (Pawn p : pawns) {
    int px = BOARD_MARGIN + p.x * CELL_SIZE;
    int py = BOARD_MARGIN + p.y * CELL_SIZE;

    // プレイヤーの色（ここでは0:赤, 1:青, 2:緑, 3:オレンジ）
    color c;
    if (p.owner == 0) c = color(0, 100, 100);      // 赤
    else if (p.owner == 1) c = color(220, 100, 100); // 青
    else if (p.owner == 2) c = color(120, 100, 65); // 緑
    else c = color(30, 100, 100);                   // オレンジ

    fill(c);
    noStroke();
    ellipse(px, py, 40, 40);  // 駒を交点に描画
    if (isSelecting && selectedPawn == p) {
      stroke(0);
      strokeWeight(3);
      noFill();
      ellipse(px, py, 50, 50); // 選択中の駒にリング
    
    }
  }
}

//クリックによって駒を置く
int currentPlayer = 0;  // 今のプレイヤー番号（0,1,2,...）
int totalPlayers = 2;   // プレイヤー人数（今は2人としておく）



//選択状態を管理する変数↓
boolean isSelecting = false;
Pawn selectedPawn = null;

//該当プレイヤーが含まれるセットを削除↓


void endTurn() {
  // 時間超過ペナルティ処理
  int elapsedSeconds = (millis() - turnStartTime) / 1000;
  int penalty = elapsedSeconds / timePenaltyInterval;
  scores[currentPlayer] -= penalty;

  // 現在のプレイヤーのターン開始時に、そのプレイヤーが含まれる指摘履歴を削除
  accusedHistory.removeIf(set -> {
    for (Pawn p : set) {
      if (p.owner == currentPlayer) return true;
    }
    return false;
  });

  // ターン進行
  currentPlayer = (currentPlayer + 1) % totalPlayers;

  // === 駒数終了チェック ===
  int[] pawnCounts = new int[totalPlayers];
  for (Pawn p : pawns) {
    pawnCounts[p.owner]++;
  }

  for (int i = 0; i < totalPlayers; i++) {
    if (pawnCounts[i] <= 2) {
      isGameOver = true;
      gameOverReason = "Player" + (i + 1) + "の駒が2個以下";
      println("ゲーム終了: " + gameOverReason);
      return;
    }
  }

  // === ターン数終了チェック ===
  if (currentPlayer == 0) {
    fullTurnCount++;  // 全員1周したときだけカウント進める
    if (maxTurns > 0 && fullTurnCount >= maxTurns+1) {
      isGameOver = true;
      gameOverReason = "最大ターン数に到達";
      println("ゲーム終了: " + gameOverReason);
      return;
    }
  }

  // 次のターンの準備
  startTurn();
  isSelecting = false;
  selectedPawn = null;
}

  

//タイマー表示
void drawTimer() {
  int elapsed = millis() - turnStartTime;
  int remaining = max(0, timePenaltyInterval - elapsed);
  fill(0);
  textAlign(RIGHT, TOP);
  textSize(16);
  text("Time: " + nf(remaining / 1000, 2) + "s", width - 20, 20);
}


//該当プレイヤーが含まれるセットを削除↑

void mousePressed() { 
  if (currentState == GameState.TITLE) return;
    if (currentState == GameState.TITLE) {
      selectedPlayers = (selectedPlayers % 4) + 2;
      selectedMaxTurns = (selectedMaxTurns == 15) ? 30 :
                         (selectedMaxTurns == 30) ? 50 :
                         (selectedMaxTurns == 50) ? -1 : 15;
      selectedTimeLimit = (selectedTimeLimit == 10) ? 20 :
                          (selectedTimeLimit == 20) ? 30 : 10;
    }
  // === 指摘モードキャンセル ===
  if (isAccusing) {
    if (mouseButton == RIGHT 
        || mouseX < BOARD_MARGIN || mouseX > BOARD_MARGIN + BOARD_PIXEL_SIZE 
        || mouseY < BOARD_MARGIN || mouseY > BOARD_MARGIN + BOARD_PIXEL_SIZE) {
      println("指摘モードをキャンセルしました");
      isAccusing = false;
      accusedPawns.clear();
      return;
    }
  }
  // グリッド座標に変換（最初に定義しておく）
  int gx = round((mouseX - BOARD_MARGIN) / (float)CELL_SIZE);
  int gy = round((mouseY - BOARD_MARGIN) / (float)CELL_SIZE);

  // ↓ 指摘モード中の処理
  if (isAccusing) {
    // 敵の駒をクリックしたか確認（履歴に含まれたら無視）
    for (Pawn p : pawns) {
      if (p.x == gx && p.y == gy && p.owner != currentPlayer 
          && !accusedPawns.contains(p)
          && !accusedHistory.contains(p)) {
        accusedPawns.add(p);
        break;
      }
    }

    if (accusedPawns.size() == 4) {
      //すでにこの組み合わせが記録されているか↓
      Set<Pawn> thisSet = new HashSet<Pawn>(accusedPawns);
      if (accusedHistory.contains(thisSet)) {
        println("この組み合わせはすでに指摘されています");
        accusedPawns.clear();
        return;
      }  
      //すでにこの組み合わせが記録されているか↑

      evaluateAccusation();  // 成功・失敗判定とスコア処理
      accusedPawns.clear();  // 次の指摘へ備える
    }

    return; // 指摘中はここで終了
  }

  // ↓ 盤の内側をクリックしたかチェック（指摘モードでなければ通常の駒操作）
  if (mouseX < BOARD_MARGIN || mouseX > BOARD_MARGIN + BOARD_PIXEL_SIZE) return;
  if (mouseY < BOARD_MARGIN || mouseY > BOARD_MARGIN + BOARD_PIXEL_SIZE) return;

  if (!isSelecting) {
    // まだ何も選択していない → 自分の駒をクリックしたか？
    for (Pawn p : pawns) {
      if (p.x == gx && p.y == gy && p.owner == currentPlayer) {
        selectedPawn = p;
        isSelecting = true;
        return;
      }
    }
  } else {
    // 駒を選んだ状態 → 移動先処理

    // 目的地に駒があればキャンセル
    for (Pawn p : pawns) {
      if (p.x == gx && p.y == gy) {
        isSelecting = false;
        selectedPawn = null;
        return;
      }
    }

    // 間に駒があるならキャンセル
    if (!isPathClear(selectedPawn.x, selectedPawn.y, gx, gy)) {
      isSelecting = false;
      selectedPawn = null;
      return;
    }

    // 移動実行
    selectedPawn.x = gx;
    selectedPawn.y = gy;

    // 挟んで取る処理
    checkCaptures(selectedPawn);

    endTurn();

  }
}

//指摘モードかどうかの判定用↓
boolean isInPointingPhase = true;  // 指摘フェーズ中か
ArrayList<Pawn> selectedForPointing = new ArrayList<Pawn>();  // 選択された他人の駒
//指摘モードかどうかの判定用↑

//↓同一円周上かどうかのやつ


void evaluateAccusation() {
  if (isOnSameCircle(accusedPawns)) {
    println("指摘成功！");
    scores[currentPlayer] += 1;

    // 一度だけ減点するために、Setでユニークなownerを集める
    HashSet<Integer> penalizedPlayers = new HashSet<Integer>();
    for (Pawn p : accusedPawns) {
      penalizedPlayers.add(p.owner);
    }
    for (int owner : penalizedPlayers) {
      scores[owner] = (scores[owner] - 1);  // または scores[owner] -= 1; で負のスコアも可
    }
    // 組み合わせを履歴に記録（再指摘防止用）
    accusedHistory.add(new HashSet<Pawn>(accusedPawns));
    Set<Pawn> thisSet = new HashSet<Pawn>(accusedPawns);
    accusedHistory.add(thisSet);
  } else {
    println("指摘失敗！");
    scores[currentPlayer] = (scores[currentPlayer] - 1);
    Set<Pawn> thisSet = new HashSet<Pawn>(accusedPawns);
    accusedHistory.add(thisSet);
  }
   // 履歴に追加（再指摘防止）
   //accusedHistory.addAll(accusedPawns);

  //制限時間ペナルティ↓
  accusedHistory.add(new HashSet<Pawn>(accusedPawns));
  startTurn(); // 指摘後にタイマーをリセット
  //制限時間ペナルティ↑

  isAccusing = false;
}
//↑同一円周上かどうかのやつ
//同一円周上かどうかのやつ(数学により判定)
boolean isOnSameCircle(ArrayList<Pawn> pawns) {
  if (pawns.size() != 4) return false;

  PVector p1 = new PVector(pawns.get(0).x, pawns.get(0).y);
  PVector p2 = new PVector(pawns.get(1).x, pawns.get(1).y);
  PVector p3 = new PVector(pawns.get(2).x, pawns.get(2).y);
  PVector p4 = new PVector(pawns.get(3).x, pawns.get(3).y);

  PVector center1 = findCircleCenter(p1, p2, p3);
  if (center1 == null) return false;

  float r = dist(center1.x, center1.y, p1.x, p1.y);
  float d = dist(center1.x, center1.y, p4.x, p4.y);

  return abs(r - d) < 0.01;
}

PVector findCircleCenter(PVector A, PVector B, PVector C) {
  float a = B.x - A.x;
  float b = B.y - A.y;
  float c = C.x - A.x;
  float d = C.y - A.y;
  float e = a * (A.x + B.x) + b * (A.y + B.y);
  float f = c * (A.x + C.x) + d * (A.y + C.y);
  float g = 2 * (a * (C.y - B.y) - b * (C.x - B.x));

  if (abs(g) < 0.0001) return null; // 共線で円が定まらない
  float cx = (d * e - b * f) / g;
  float cy = (a * f - c * e) / g;

  return new PVector(cx, cy);
}


void applySettings() {
  totalPlayers = selectedPlayers;
  maxTurns = selectedMaxTurns;
  timePenaltyInterval = selectedTimeLimit * 1000;
}

void keyPressed() {
  if (currentState == GameState.TITLE) {
    if (keyCode == LEFT) {
      changeSelection(-1);
    } else if (keyCode == RIGHT) {
      changeSelection(1);
    } else if (keyCode == ENTER || key == '\n') {
      advanceTitleState();
        if (titleState == TitleState.READY_TO_START) {
          applySettings();  // 設定をゲームに反映
          setupGame();      // ゲーム初期化
          currentState = GameState.PLAYING; // ゲーム開始
        }
    }
  }
  else if (currentState == GameState.PLAYING) {
    if (key == 'a' || key == 'A') {
      isAccusing = true;
      accusedPawns.clear();
    }
  }
}

void changeSelection(int delta) {
  switch (titleState) {
    case SELECT_PLAYERS:
      selectedPlayers = constrain(selectedPlayers + delta, 2, 4);
      break;
    case SELECT_TURNS:
      turnIndex = (turnIndex + delta + possibleTurns.length) % possibleTurns.length;
      selectedMaxTurns = possibleTurns[turnIndex];
      break;
    case SELECT_TIME:
      timeIndex = (timeIndex + delta + possibleTimeLimits.length) % possibleTimeLimits.length;
      selectedTimeLimit = possibleTimeLimits[timeIndex];
      break;
  }
}

void advanceTitleState() {
  switch (titleState) {
    case SELECT_PLAYERS:
      titleState = TitleState.SELECT_TURNS;
      break;
    case SELECT_TURNS:
      titleState = TitleState.SELECT_TIME;
      break;
    case SELECT_TIME:
      titleState = TitleState.READY_TO_START;
      break;
    case READY_TO_START:
      currentState = GameState.PLAYING;
      totalPlayers = selectedPlayers;
      maxTurns = selectedMaxTurns;
      maxTurnLimit = selectedMaxTurns;
      timePenaltyInterval = selectedTimeLimit * 1000;
      setupGame();  // ← 実際のゲームの初期化
      break;
  }
}



//間に駒があるかチェック↓
boolean isPathClear(int x1, int y1, int x2, int y2) {
  // 直線移動のみ（縦 or 横）
  if (x1 != x2 && y1 != y2) return false;

  int dx = Integer.compare(x2, x1); // -1, 0, or 1
  int dy = Integer.compare(y2, y1);

  int cx = x1 + dx;
  int cy = y1 + dy;

  while (cx != x2 || cy != y2) {
    for (Pawn p : pawns) {
      if (p.x == cx && p.y == cy) return false;
    }
    cx += dx;
    cy += dy;
  }

  return true;
}

//挟んでいる敵の駒を探す関数の定義↓
void checkCaptures(Pawn movedPawn) {
  int[][] directions = {
    {1, 0}, {-1, 0},  // 横
    {0, 1}, {0, -1}   // 縦
  };

  for (int[] dir : directions) {
    int dx = dir[0];
    int dy = dir[1];

    ArrayList<Pawn> toCapture = new ArrayList<Pawn>();
    int cx = movedPawn.x + dx;
    int cy = movedPawn.y + dy;

    while (cx >= 0 && cx < BOARD_SIZE && cy >= 0 && cy < BOARD_SIZE) {
      Pawn found = null;
      for (Pawn p : pawns) {
        if (p.x == cx && p.y == cy) {
          found = p;
          break;
        }
      }

      if (found == null) {
        break; // 空きならやめる
      }

      if (found.owner == movedPawn.owner) {
        // 自分の駒で挟んだ！
        if (!toCapture.isEmpty()) {
          // キャプチャ実行
          for (Pawn captured : toCapture) {
            pawns.remove(captured);
            scores[movedPawn.owner]++;  // スコア加算
          }
        }
        break;
      } else {
        toCapture.add(found); // 敵の駒 → 候補に追加
      }

      cx += dx;
      cy += dy;
    }
  }
}

//スコア描画用の関数の定義↓
void drawScores() {
  fill(0);
  textSize(50);
  textAlign(LEFT);

  int baseX = BOARD_MARGIN + BOARD_PIXEL_SIZE + 50; // 盤の右隣に表示
  int baseY = BOARD_MARGIN;

  for (int i = 0; i < totalPlayers; i++) {
    color c;
    if (i == 0) c = color(0, 100, 100);      // 赤
    else if (i == 1) c = color(220, 100, 100); // 青
    else if (i == 2) c = color(120, 100, 65); // 緑
    else c = color(30, 100, 100);             // オレンジ

    fill(c);
    text("Player " + (i + 1) + ": " + scores[i] + " pt", baseX, baseY + i * 40);
  }
  fill(0);
  textSize(20);
  text("Now Playng: Player " + (currentPlayer + 1), baseX, baseY + totalPlayers * 40 + 20);
}