typedef struct Point Point;

struct Point {
    float x;
    float y;
};

void point_add(Point* a, Point* b, Point* dest)
{
    dest->x = a->x + b->x;
    dest->y = a->y + b->y;
}