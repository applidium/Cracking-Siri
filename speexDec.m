#include <speex/speex.h>
#import <Foundation/Foundation.h>

@interface NSData (Hexadecimal)
- (NSData *)initWithHexadecimalString:(NSString *)string;
+ (NSData *)dataWithHexadecimalString:(NSString *)string;
@end

unsigned char _hexCharToInteger(unsigned char hexChar) {
    if (hexChar >= '0' && hexChar <= '9') {
        return (hexChar - '0') & 0xF;
    } else {
        return ((hexChar - 'A')+10) & 0xF;
    }
}

@implementation NSData (Hexadecimal)
- (id)initWithHexadecimalString:(NSString *)string {
    const char * hexstring = [string UTF8String];
    int dataLength = [string length] / 2;
    unsigned char * data = malloc(dataLength);
    if (data == nil) {
        return nil;
    }
    int i = 0;
    for (i = 0; i < dataLength; i++) {
        unsigned char firstByte = hexstring[2*i];
        unsigned char secondByte = hexstring[2*i+1];
        unsigned char byte = (_hexCharToInteger(firstByte) << 4) + _hexCharToInteger(secondByte);
        data[i] = byte;
    }
    self = [self initWithBytes:data length:dataLength];
    free(data);
    return self;
}

+ (NSData *)dataWithHexadecimalString:(NSString *)string {
    return [[[self alloc] initWithHexadecimalString:string] autorelease];
}
@end

int main(int argc, char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    SpeexBits bits;
    void *dec_state;
    speex_bits_init(&bits);
    dec_state = speex_decoder_init(&speex_wb_mode);
    
    int frame_size = 0;
    speex_decoder_ctl(dec_state, SPEEX_GET_FRAME_SIZE, &frame_size); 
   

    NSString * fileContents = [NSString stringWithContentsOfFile:@"input.sif" encoding:NSUTF8StringEncoding error:NULL];

    NSMutableData * decodedRawAudio = [[NSMutableData alloc] init];
    spx_int16_t * output = malloc(sizeof(spx_int16_t)*frame_size);
    
    for (NSString * frame in [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
      NSLog(@"frame = %@", frame);
      NSData * frameData = [NSData dataWithHexadecimalString:frame];

      speex_bits_read_from(&bits, ((char *)[frameData bytes]), [frameData length]);

      while (speex_decode_int(dec_state, &bits, output) == 0) {
        NSData * decodedFrame = [NSData dataWithBytes:(const void *)output
                                               length:frame_size*sizeof(spx_int16_t)];
        [decodedRawAudio appendData:decodedFrame];
      }
    }

    NSLog(@"Done ! decoded size = %d", decodedRawAudio.length);
    [decodedRawAudio writeToFile:@"output.raw" atomically:NO];

    free(output);

    speex_bits_destroy(&bits);
    speex_decoder_destroy(dec_state);
    [pool drain];
}
