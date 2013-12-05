//
//  OpenGLView.h
//  OPenGLV-Rect
//
//  Created by msp msp on 13-4-10.
//  Copyright (c) 2013年 msp msp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>

typedef struct Matrix4
{
	float   m[4][4];
} Matrix4;

@interface OpenGLView : UIView
{
    EAGLContext * m_pContext;
    CAEAGLLayer * m_pLayer;
    GLuint       m_iProgram;
    GLuint       m_iPostionSlot;
    GLuint       m_iModeView;
    GLuint       m_iRenderBuffer;
    GLuint       m_iFrameBuffer;
    
    Matrix4      m_pModelViewMatrix;
    Matrix4      m_pProjectionMatrix;
    float        m_fScaleX;
    float        m_fScaleY;
    GLuint       m_iModelViewSlot;
    GLuint       m_iProjectionSlot;
    GLuint       m_iTexCoordSlot;
    GLuint       m_iTextureUniform;
    GLuint       m_iImageSlot;

    
    
}
- (void)SetupLayer;
- (void)SetupContext;
- (void)SetupRenderBuffer;
- (void)SetupFrameBuffer;
- (void)Render;
- (GLuint)LoadShader:(GLenum)shaderType name:(NSString*)shaderFileName;
- (GLuint)setupTexture:(NSString *)fileName;
- (void)CompileShader;
- (void)ZoomOut;
- (void)ZoomIn;
@end
