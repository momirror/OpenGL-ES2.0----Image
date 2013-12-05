attribute vec4 position;
uniform mat4 projection;
uniform mat4 modelview;
attribute vec2 TexCoordIn;
varying vec2 TexCoordOut; 
void main(void)
{
    gl_Position =  modelview *position;
    TexCoordOut = TexCoordIn;
}

