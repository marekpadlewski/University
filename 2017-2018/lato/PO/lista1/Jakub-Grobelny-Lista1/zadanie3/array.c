// Programowanie Obiektowe
// Jakub Grobelny 300481
// Zadanie 3 lista 1

#include "array.h"

Array create_array(type neutral_element)
{
    Array result;

    result.capacity = 0;
    result.beginning = 0;

    result.neutral_element = neutral_element;

    result.elements = (type*)malloc(sizeof(type) * result.capacity);

    return result;
}

void print_array(Array* array, void print_fun(type))
{
    if (!array->capacity)
    {
        printf("empty\n");
        return;
    }

    for (int i = array->beginning; i < array->capacity + array->beginning; i++)
    {
        printf("[%d] = ", i);
        print_fun(get_element(array, i));
        putchar('\n');
    }
}

int abs(int x)
{
    return x < 0 ? - x : x;
}

void add_element(Array* array, int index, type element)
{
    if (!array->capacity)
    {
        array->capacity = 1;
        array->elements = (type*)malloc(sizeof(type) * array->capacity);
        array->beginning = index;
        array->elements[0] = element;
        return;
    }

    if (index < array->beginning || index > array->beginning + array->capacity - 1) // new index is outside
    {
        int delta_capacity = abs(index < array->beginning ? (array->beginning - index) : (index - (array->beginning + array->capacity - 1)));

        array->capacity += delta_capacity;
        array->elements = (type*)realloc(array->elements, sizeof(type) * array->capacity);

        // setting new space to the neutral element
        for (int i = array->capacity - delta_capacity; i < array->capacity; i++)
            array->elements[i] = array->neutral_element;

        if (index < array->beginning)
        {
            for (int i = array->capacity - delta_capacity - 1; i >= 0; i--) // shifting to the right
            {
                array->elements[i + delta_capacity] = array->elements[i];
            }

            // clearing empty space to neutral element
            for (int i = 0; i < delta_capacity; i++)
                array->elements[i] = array->neutral_element;

            array->beginning = index;
            array->elements[0] = element;
        }
        else // index is the last one
            array->elements[array->capacity - 1] = element;
    }
    else // index lies in the range
        array->elements[index - array->beginning] = element; 
}

type get_element(Array* array, int index)
{
    return (array->elements[index - array->beginning]);
}

void destroy_array(Array* array)
{
    free(array->elements);
}
