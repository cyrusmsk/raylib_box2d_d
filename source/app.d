import std.stdio;
import std.string;
import raylib;
import box2d_lib;

enum GROUND_COUNT = 14;
enum BOX_COUNT = 10;

struct Entity
{
  b2BodyId bodyId;
  b2Vec2 extent;
  Texture texture;
}

void drawEntity(Entity* entity)
{
  b2Vec2 p = b2Body_GetWorldPoint(entity.bodyId, b2Vec2(-entity.extent.x, -entity.extent.y));
  b2Rot rotation = b2Body_GetRotation(entity.bodyId);
  float radians = b2Rot_GetAngle(rotation);

  auto ps = Vector2(p.x, p.y);
  DrawTextureEx(entity.texture, ps, RAD2DEG * radians, 1.0f, Colors.WHITE);
}

void main()
{
  writeln("Starting a box2d/raylib example.");
  int width = 1300;
  int height = 1000;

  validateRaylibBinding();

  InitWindow(width, height, "box2d-raylib");
  SetTargetFPS(60);
  scope (exit)
    CloseWindow(); // see https://dlang.org/spec/statement.html#scope-guard-statement

  float lengthUnitsPerMeter = 128.0f;
  b2SetLengthUnitsPerMeter(lengthUnitsPerMeter);

  b2WorldDef worldDef = b2DefaultWorldDef();

  // Realistic gravity is achieved by multiplying gravity by the length unit.
  worldDef.gravity.y = 9.8f * lengthUnitsPerMeter;
  b2WorldId worldId = b2CreateWorld(&worldDef);

  Texture groundTexture = LoadTexture("assets/ground.png");
  Texture boxTexture = LoadTexture("assets/box.png");

  b2Vec2 groundExtent = b2Vec2(0.5f * groundTexture.width, 0.5f * groundTexture.height);
  b2Vec2 boxExtent = b2Vec2(0.5f * boxTexture.width, 0.5f * boxTexture.height);

  // These polygons are centered on the origin and when they are added to a body they
  // will be centered on the body position.
  b2Polygon groundPolygon = b2MakeBox(groundExtent.x, groundExtent.y);
  b2Polygon boxPolygon = b2MakeBox(boxExtent.x, boxExtent.y);

  Entity[GROUND_COUNT] groundEntities;
  foreach (i; 0 .. GROUND_COUNT)
  {
    Entity* entity = &groundEntities[i];
    b2BodyDef bodyDef = b2DefaultBodyDef();
    bodyDef.position = b2Vec2((2.0f * i + 2.0f) * groundExtent.x, height - groundExtent.y - 100.0f);

    entity.bodyId = b2CreateBody(worldId, &bodyDef);
    entity.extent = groundExtent;
    entity.texture = groundTexture;
    b2ShapeDef shapeDef = b2DefaultShapeDef();
    b2CreatePolygonShape(entity.bodyId, &shapeDef, &groundPolygon);
  }

  Entity[BOX_COUNT] boxEntities;
  int boxIndex = 0;
  foreach (i; 0 .. 4)
  {
    float y = height - groundExtent.y - 100.0f - (2.5f * i + 2.0f) * boxExtent.y - 20.0f;
    foreach (j; i .. 4)
    {
      float x = 0.5f * width + (3.0f * j - i - 3.0f) * boxExtent.x;
      //assert(boxIndex < BOX_COUNT);

      auto entity = &boxEntities[boxIndex];
      b2BodyDef bodyDef = b2DefaultBodyDef();
      bodyDef.type = b2_dynamicBody;
      bodyDef.position = b2Vec2(x, y);
      entity.bodyId = b2CreateBody(worldId, &bodyDef);
      entity.texture = boxTexture;
      entity.extent = boxExtent;
      b2ShapeDef shapeDef = b2DefaultShapeDef();
      b2CreatePolygonShape(entity.bodyId, &shapeDef, &boxPolygon);

      boxIndex += 1;
    }
  }

  bool pause = false;

  while (!WindowShouldClose())
  {
    if (IsKeyPressed(KeyboardKey.KEY_P))
    {
      pause = !pause;
    }

    if (pause == false)
    {
      float deltaTime = GetFrameTime();
      b2World_Step(worldId, deltaTime, 4);
    }

    BeginDrawing();
    scope (exit)
      EndDrawing();

    ClearBackground(Colors.DARKGRAY);
    char* message = cast(char*) "Hello Box2D!".toStringz;

    int fontSize = 36;
    int textWidth = MeasureText("Hello Box2D!", fontSize);
    DrawText(message, (width - textWidth) / 2, 50, fontSize, Colors.LIGHTGRAY);

    foreach (ent; groundEntities)
      drawEntity(&ent);
    foreach (ent; boxEntities)
      drawEntity(&ent);
  }

  UnloadTexture(groundTexture);
  UnloadTexture(boxTexture);
  CloseWindow();

  writeln("Ending a box2d/raylib example.");
}
