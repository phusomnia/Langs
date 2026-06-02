module math::point;

struct Point 
{
	float x;
	float y;
}

fn Point new(float x, float y)
{
    return { .x = x, .y = y };
}

extern fn void point_add(Point* a, Point *b, Point* dest);