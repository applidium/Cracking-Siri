#include <speex/speex.h>
#import <Foundation/Foundation.h>

#define MAX_FRAME_SIZE 1024

@interface NSData (HexadecimalRepresentation)
- (NSString *)hexadecimalRepresentation;
@end

@implementation NSData (HexadecimalRepresentation)
- (NSString *)hexadecimalRepresentation {
	static const char * hexChars = "0123456789ABCDEF";
    
	const unsigned char * src = (const unsigned char *)[self bytes];
	int srcLength = [self length];
	
	char * hexString = malloc(2*srcLength+1);
	if (hexString == NULL) {
		return nil;
	}
        int i = 0;    
	for (i=0; i<srcLength; i++) {
		unsigned char currentByte = src[i];
		hexString[2*i] =   hexChars[currentByte >> 4];
		hexString[2*i+1] = hexChars[currentByte & 0xF];
	}
	hexString[2*srcLength] = 0; // NULL-terminated string
    
	NSString * hexRep = [NSString stringWithUTF8String:hexString];
	free(hexString);
	
	return hexRep;
}
@end

int main(int argc, char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

SpeexBits bits;
void *enc_state;

speex_bits_init(&bits);
enc_state = speex_encoder_init(&speex_wb_mode);

  int quality = 8;
  speex_encoder_ctl(enc_state, SPEEX_SET_QUALITY, &quality);

  int frame_size;
  speex_encoder_ctl(enc_state, SPEEX_GET_FRAME_SIZE, &frame_size);
//frame_size = 3200;

//NSLog(@"Frame size is %d", frame_size);


  NSData * rawData = [NSData dataWithContentsOfFile:@"tentative.raw"];

  char * outputFrameData = malloc(MAX_FRAME_SIZE);


  int i = 0;
  int total_size = 0;
  for (i = 0; i < [rawData length]/(sizeof(short)*frame_size); i++) {
    speex_bits_reset(&bits);
    short * pointer = (short *)[rawData bytes];
    speex_encode_int(enc_state, pointer+i*frame_size, &bits);
    int nbBytes = speex_bits_write(&bits, outputFrameData, MAX_FRAME_SIZE);
    total_size += nbBytes;
//printf("%d\n", nbBytes);
    NSData * frameData = [NSData dataWithBytes:outputFrameData
                                        length:nbBytes];
    printf("%s\n", [[frameData hexadecimalRepresentation] UTF8String]);
  }
 //NSLog(@"Total size = %d", total_size);
  speex_bits_destroy(&bits);
  speex_encoder_destroy(enc_state);
  [pool drain];

}
