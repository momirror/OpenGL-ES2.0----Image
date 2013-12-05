//
//  OpenGLView.m
//  OPenGLV-Rect
//
//  Created by msp msp on 13-4-10.
//  Copyright (c) 2013年 msp msp. All rights reserved.
//

#import "OpenGLView.h"

@implementation OpenGLView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        m_fScaleX = m_fScaleY = 1;
        
        [self SetupLayer];
        [self SetupContext];
        [self SetupRenderBuffer];
        [self SetupFrameBuffer];
        [self CompileShader];
//        [self setupProjection];
        m_iImageSlot = [self setupTexture:@"fish.png"];
        [self Render];
    }
    return self;
}

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (void)SetupLayer
{
    m_pLayer = (CAEAGLLayer*)self.layer;
    m_pLayer.opaque = YES;
    
//    m_pLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
//                                     [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}


- (void)SetupContext
{
    m_pContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if(!m_pContext)
    {
        NSLog(@"Init context failed");
        exit(1);
    }
    
    if(![EAGLContext setCurrentContext:m_pContext])
    {
        exit(1);
    }
}

- (void)SetupRenderBuffer
{
    glGenRenderbuffers(1, &m_iRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, m_iRenderBuffer);
    [m_pContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:m_pLayer];
    
}

- (void)SetupFrameBuffer
{
    glGenFramebuffers(1, &m_iFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, m_iFrameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, m_iRenderBuffer);
}



- (GLuint)LoadShader:(GLenum)shaderType name:(NSString*)shaderFileName
{
    GLuint iShader = glCreateShader(shaderType);
    NSString * strFilePath = [[NSBundle mainBundle] pathForResource:shaderFileName ofType:nil];
    NSError * error;
    NSString * strFileContent = [NSString stringWithContentsOfFile:strFilePath encoding:NSUTF8StringEncoding error:&error];
    if(!strFileContent)
    {
        NSLog(@"Error %@",error);
        exit(1);
    }
    
    const char * shaderStringWithUTF8 = [strFileContent UTF8String];
    int iShaderStringLen = strlen(shaderStringWithUTF8);
    
    glShaderSource(iShader, 1, &shaderStringWithUTF8, &iShaderStringLen);
    glCompileShader(iShader);
    
    GLint compileSucce;
    glGetShaderiv(iShader, GL_COMPILE_STATUS, &compileSucce);
    
    if(compileSucce == GL_FALSE)
    {
        GLchar message[256];
        glGetShaderInfoLog(iShader, 256, 0, &message[0]);
        NSLog(@"shader:%@ compile error:%s",shaderFileName,message);
        exit(1);
    }
    
    return iShader;
}

- (void)CompileShader
{
    GLuint iVertexShader = [self LoadShader:GL_VERTEX_SHADER name:@"vertex.shader"];
    GLuint iFragmentShader = [self LoadShader:GL_FRAGMENT_SHADER name:@"fragment.shader"];
    
    m_iProgram = glCreateProgram();
    glAttachShader(m_iProgram, iVertexShader);
    glAttachShader(m_iProgram, iFragmentShader);
    glLinkProgram(m_iProgram);
    
    GLint linkState;
    glGetProgramiv(m_iProgram, GL_LINK_STATUS, &linkState);
    if(linkState == GL_FALSE)
    {
        GLchar message[256];
        glGetProgramInfoLog(m_iProgram, 256, 0, &message[0]);
        NSLog(@"program link %s",message);
        exit(1);
    }
    
    glUseProgram(m_iProgram);
    m_iPostionSlot = glGetAttribLocation(m_iProgram, "position");
    m_iModelViewSlot = glGetUniformLocation(m_iProgram, "modelview");
    m_iProjectionSlot = glGetUniformLocation(m_iProgram, "projection");
    m_iTexCoordSlot = glGetAttribLocation(m_iProgram, "TexCoordIn");
//    glEnableVertexAttribArray(m_iTexCoordSlot);

    m_iTextureUniform = glGetUniformLocation(m_iProgram, "Texture");
}

void ksPerspective(Matrix4 * result, float fovy, float aspect, float nearZ, float farZ)
{
	float frustumW, frustumH;
    
	frustumH = tanf( fovy / 360.0f * M_PI ) * nearZ;
	frustumW = frustumH * aspect;
    
	ksFrustum(result, -frustumW, frustumW, -frustumH, frustumH, nearZ, farZ);
}

void ksFrustum(Matrix4 * result, float left, float right, float bottom, float top, float nearZ, float farZ)
{
	float       deltaX = right - left;
	float       deltaY = top - bottom;
	float       deltaZ = farZ - nearZ;
	Matrix4    frust;
    
	if ( (nearZ <= 0.0f) || (farZ <= 0.0f) ||
		(deltaX <= 0.0f) || (deltaY <= 0.0f) || (deltaZ <= 0.0f) )
		return;
    
	frust.m[0][0] = 2.0f * nearZ / deltaX;
	frust.m[0][1] = frust.m[0][2] = frust.m[0][3] = 0.0f;
    
	frust.m[1][1] = 2.0f * nearZ / deltaY;
	frust.m[1][0] = frust.m[1][2] = frust.m[1][3] = 0.0f;
    
	frust.m[2][0] = (right + left) / deltaX;
	frust.m[2][1] = (top + bottom) / deltaY;
	frust.m[2][2] = -(nearZ + farZ) / deltaZ;
	frust.m[2][3] = -1.0f;
    
	frust.m[3][2] = -2.0f * nearZ * farZ / deltaZ;
	frust.m[3][0] = frust.m[3][1] = frust.m[3][3] = 0.0f;
    
	ksMatrixMultiply(result, &frust, result);
}

void ksMatrixMultiply(Matrix4 * result, const Matrix4 *a, const Matrix4 *b)
{
	Matrix4 tmp;
	int i;
    
	for (i = 0; i < 4; i++)
	{
		tmp.m[i][0] = (a->m[i][0] * b->m[0][0]) +
        (a->m[i][1] * b->m[1][0]) +
        (a->m[i][2] * b->m[2][0]) +
        (a->m[i][3] * b->m[3][0]) ;
        
		tmp.m[i][1] = (a->m[i][0] * b->m[0][1]) +
        (a->m[i][1] * b->m[1][1]) +
        (a->m[i][2] * b->m[2][1]) +
        (a->m[i][3] * b->m[3][1]) ;
        
		tmp.m[i][2] = (a->m[i][0] * b->m[0][2]) +
        (a->m[i][1] * b->m[1][2]) +
        (a->m[i][2] * b->m[2][2]) +
        (a->m[i][3] * b->m[3][2]) ;
        
		tmp.m[i][3] = (a->m[i][0] * b->m[0][3]) +
        (a->m[i][1] * b->m[1][3]) +
        (a->m[i][2] * b->m[2][3]) +
        (a->m[i][3] * b->m[3][3]) ;
	}
    
	memcpy(result, &tmp, sizeof(Matrix4));
}


-(void)setupProjection
{
    // Generate a perspective matrix with a 60 degree FOV
    //
    float aspect = self.frame.size.width / self.frame.size.height;
    [self MatrixLoadIdentity:&m_pProjectionMatrix];
    ksPerspective(&m_pProjectionMatrix, 60.0, aspect, 0.0f, 0.0f);
    
    // Load projection matrix
    glUniformMatrix4fv(m_iProjectionSlot, 1, GL_FALSE, (GLfloat*)&m_pProjectionMatrix.m[0][0]);
}

- (void)Render
{
    [self ScaleToFit];
    
    glClearColor(1.0, 1, 0.2, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    
    [self draw];

    
    
    [m_pContext presentRenderbuffer:GL_RENDERBUFFER];

}



- (void)ScaleToFit
{

    //单位矩阵
    [self MatrixLoadIdentity:&m_pModelViewMatrix];
    [self MatrixScale:&m_pModelViewMatrix sx:m_fScaleX sy:m_fScaleY sz:1];
    glUniformMatrix4fv(m_iModelViewSlot, 1, GL_FALSE, (GLfloat*)&m_pModelViewMatrix.m[0][0]);
}


- (void)draw
{
    //屏幕正中为原点，各上下左右的长度各为一个单位
    GLfloat vertices[] = {
        -1., -1.0f,0,//左下
        1.0f, -1.0f,0,//右下
        -1.0f,  1.0f,0,//左上
        1.0f,  1.0f,0//右上
    };
    
//    GLfloat vertices[] = {
//        -(CGRectGetWidth(self.frame)/CGRectGetWidth([UIScreen mainScreen].bounds)), -(CGRectGetHeight(self.frame)/CGRectGetHeight([UIScreen mainScreen].bounds)),0,//左下
//        (CGRectGetWidth(self.frame)/CGRectGetWidth([UIScreen mainScreen].bounds)), -(CGRectGetHeight(self.frame)/CGRectGetHeight([UIScreen mainScreen].bounds)),0,//右下
//        -(CGRectGetWidth(self.frame)/CGRectGetWidth([UIScreen mainScreen].bounds)),  (CGRectGetHeight(self.frame)/CGRectGetHeight([UIScreen mainScreen].bounds)),0,//左上
//        (CGRectGetWidth(self.frame)/CGRectGetWidth([UIScreen mainScreen].bounds)),  (CGRectGetHeight(self.frame)/CGRectGetHeight([UIScreen mainScreen].bounds)),0//右上


    
    //纹理坐标，对应的是iOS坐标系统
    static const GLfloat coordVertices[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f,  0.0f,
        1.0f,  0.0f,
    };

    //右下部分
//    static const GLfloat coordVertices[] =
//    {
//        0.5f, 1,
//        1, 1,
//        0.5f, 0.5f,
//        1, 0.5
//    };
    
//    //右上部分
//    static const GLfloat coordVertices[] =
//    {
//        0.5f,0.5f,
//        1,0.5,
//        0.5f, 0,
//        1, 0
//    };
    
//    //左下部分
//    static const GLfloat coordVertices[] =
//    {
//        0,1,
//        0.5,1,
//        0,0.5,
//        0.5,0.5
//        
//    };
    
    //左上部分
//    static const GLfloat coordVertices[] =
//    {
//       0,0.5,
//        0.5,0.5,
//        0,0,
//        0.5,0
//        
//    };




    
    
    
    //纹理坐标与顶点坐标一一对应。由于iOS的原点坐标在左上角，而OpenGL的原点坐标在左下角，所以要垂直翻转，
    
    glVertexAttribPointer(m_iPostionSlot, 3, GL_FLOAT, GL_FALSE, 0, vertices );
    glEnableVertexAttribArray(m_iPostionSlot);
    
    glVertexAttribPointer(m_iTexCoordSlot, 2, GL_FLOAT, GL_FALSE,0, coordVertices);
    glEnableVertexAttribArray(m_iTexCoordSlot);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, m_iImageSlot);
    glUniform1i(m_iTextureUniform, 0);
 
//    glColorMask(1, 0, 0, 1);
   
     glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
//    glDrawElements(GL_LINES, sizeof(indices)/sizeof(GLubyte), GL_UNSIGNED_BYTE, indices);
}


//设置图案纹理
- (GLuint)setupTexture:(NSString *)fileName
{
    //
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    
    // 2
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte * spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    // 3
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    // 4
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    //过滤，不限制图片大小，不用遵循2的N次幂这个规则
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    //处理透明背景
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
//    glBlendFunc(GL_ONE, GL_ONE);
    
    free(spriteData);
    return texName;
}


//单位矩阵
- (void)MatrixLoadIdentity:(Matrix4 *) result
{
	memset(result, 0x0, sizeof(Matrix4));
    
	result->m[0][0] = 1.0f;
	result->m[1][1] = 1.0f;
	result->m[2][2] = 1.0f;
	result->m[3][3] = 1.0f;
}

//平移
- (void)MatrixTranslate:(Matrix4 *) result tx:(float)tx ty:(float)ty tz:(float)tz
{
	result->m[3][0] += (result->m[0][0] * tx + result->m[1][0] * ty + result->m[2][0] * tz);
	result->m[3][1] += (result->m[0][1] * tx + result->m[1][1] * ty + result->m[2][1] * tz);
	result->m[3][2] += (result->m[0][2] * tx + result->m[1][2] * ty + result->m[2][2] * tz);
	result->m[3][3] += (result->m[0][3] * tx + result->m[1][3] * ty + result->m[2][3] * tz);
}

//缩放
- (void)MatrixScale:(Matrix4 *)result sx:(float)sx sy:(float)sy sz:(float)sz
{
	result->m[0][0] *= sx;
	result->m[0][1] *= sx;
	result->m[0][2] *= sx;
	result->m[0][3] *= sx;
    
	result->m[1][0] *= sy;
	result->m[1][1] *= sy;
	result->m[1][2] *= sy;
	result->m[1][3] *= sy;
    
	result->m[2][0] *= sz;
	result->m[2][1] *= sz;
	result->m[2][2] *= sz;
	result->m[2][3] *= sz;
}


- (void)ZoomOut
{
    m_fScaleX *= 1.2;
    m_fScaleY *= 1.2;
    
    [self Render];
}

- (void)ZoomIn
{
    m_fScaleX /= 1.2;
    m_fScaleY /= 1.2;
    
    [self Render];
}
@end
